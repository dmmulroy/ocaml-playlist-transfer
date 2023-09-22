open Shared
open Syntax
open Let

type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : Track.t;
  video_thumbnail : video_thumbnail option; [@default None]
}
[@@deriving yojson { strict = false }]

and video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

type t = {
  collaborative : bool;
  description : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource.reference;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  primary_color : string option; [@default None]
  public : bool option; [@default None]
  resource_type : Resource.t; [@key "type"]
  snapshot_id : string;
  tracks : playlist_track Page.t;
  uri : string;
}
[@@deriving yojson]

module Add_tracks_input = struct
  type t = { playlist_id : string; uris : string list } [@@deriving make]

  let to_yojson { uris; _ } =
    `Assoc [ ("uris", `List (List.map (fun uri -> `String uri) uris)) ]
end

module Add_tracks_output = struct
  type t = { snapshot_id : string } [@@deriving yojson]
end

module Add_tracks = Spotify_rest_client.Make (struct
  type input = Add_tracks_input.t
  type output = Add_tracks_output.t [@@deriving yojson]

  let name = "Add_tracks"

  let make_endpoint (playlist_id : string) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ playlist_id
    ^ "/tracks"

  let to_http_request input =
    let open Infix.Result in
    let input_json = Add_tracks_input.to_yojson input in
    let| body =
      Http.Body.of_yojson input_json >|? fun str ->
      Spotify_error.make ~source:(`Serialization (`Json input_json)) str
    in
    Lwt.return_ok
    @@ Http.Request.make ~meth:`POST ~body
         ~uri:(make_endpoint input.playlist_id)
         ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end)

let add_tracks = Add_tracks.request

module Create_input = struct
  type t = {
    collaborative : bool option;
    description : string option;
    name : string;
    public : bool option;
    user_id : string;
  }
  [@@deriving yojson]

  let make ?collaborative ?description ?public ~name ~user_id () =
    { collaborative; description; name; public; user_id }
end

module Create_output = struct
  type nonrec t = t
end

module CreatePlaylist = Spotify_rest_client.Make (struct
  type input = Create_input.t
  type output = Create_output.t

  let name = "Create_playlist"
  let output_of_yojson = of_yojson

  let make_endpoint (user_id : string) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/users/" ^ user_id
    ^ "/playlists"

  let to_http_request input =
    let open Infix.Result in
    let input_json = Create_input.to_yojson input in
    let| body =
      Http.Body.of_yojson input_json >|? fun str ->
      Spotify_error.make ~source:(`Serialization (`Json input_json)) str
    in
    Lwt.return_ok
    @@ Http.Request.make ~meth:`POST ~body ~uri:(make_endpoint input.user_id) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end)

let create = CreatePlaylist.request

module Get_featured_input = struct
  type t = {
    country : string option;
    locale : string option;
    timestamp : string option;
    limit : int option;
    offset : int option;
  }

  let make ?country ?locale ?timestamp ?limit ?offset () =
    { country; locale; timestamp; limit; offset }

  let to_query_params { country; locale; timestamp; limit; offset } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("country", country);
        ("locale", locale);
        ("timestamp", timestamp);
        ("limit", Option.map string_of_int limit);
        ("offset", Option.map string_of_int offset);
      ]
end

module Get_featured_output = struct
  type t = { message : string; playlists : Simple_playlist.t Page.t }
  [@@deriving yojson]
end

module Get_featured = Spotify_rest_client.Make (struct
  type input = Get_featured_input.t
  type output = Get_featured_output.t [@@deriving yojson]

  let name = "Get_featured"

  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"

  let make_endpoint input =
    Http.Uri.add_query_params' base_endpoint
    @@ Get_featured_input.to_query_params input

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_featured = Get_featured.request

module Get_by_id_input = struct
  type t = {
    id : string;
    additional_types : [ `Track | `Episode ] list option;
    fields : string option;
    market : string option;
  }

  let to_query_params { additional_types; fields; market; _ } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("fields", fields);
        ("market", market);
        ( "additional_types",
          Option.map
            (fun additional_types' ->
              String.concat "," @@ List.map Resource.to_string additional_types')
            additional_types );
      ]

  let make ?additional_types ?fields ?market ~id () =
    Spotify_request.make { id; additional_types; fields; market }
end

module Get_by_id_output = struct
  type playlist = t [@@deriving yojson]
  type t = playlist [@@deriving yojson]
end

module Get_playlist_by_id = Spotify_rest_client.Make (struct
  type input = Get_by_id_input.t Spotify_request.t
  type output = Get_by_id_output.t Spotify_response.t [@@deriving of_yojson]

  let name = "Get_playlist_by_id"

  let make_endpoint (request : input) =
    let base_endpoint =
      Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/"
      ^ request.input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params request.input

  let to_http_request (request : input) =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint request) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_by_id = Get_playlist_by_id.request

module Get_tracks_input = struct
  type t = string

  let make (playlist_id : t) = Spotify_request.make playlist_id
end

module Get_tracks_output = struct
  type t = playlist_track Page.t [@@deriving yojson { strict = false }]
end

module Get_tracks = Spotify_rest_client.Make (struct
  type input = Get_tracks_input.t Spotify_request.t
  type output = Get_tracks_output.t Spotify_response.t

  let name = "Get_tracks"

  let make_endpoint (request : input) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/"
    ^ request.input ^ "/tracks"

  let to_http_request (request : input) =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint request) ()

  let of_http_response http_response =
    Infix.Lwt_result.(
      Spotify_rest_client.handle_response
        ~deserialize:Get_tracks_output.of_yojson http_response
      >|= fun playlist_track_page ->
      let page = Pagination.make playlist_track_page in
      Spotify_response.make ~data:playlist_track_page ~page)
end)

let get_tracks = Get_tracks.request
