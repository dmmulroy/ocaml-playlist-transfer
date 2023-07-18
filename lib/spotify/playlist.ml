type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : Track.t;
  video_thumbnail : video_thumbnail option; [@default None]
}
[@@deriving yojson]

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

type create_playlist_input = {
  collaborative : bool option;
  description : string option;
  name : string;
  public : bool option;
  user_id : string;
}
[@@deriving yojson]

module CreatePlaylist = Spotify_request.Make (struct
  type input = create_playlist_input [@@deriving yojson]
  type options = unit
  type output = t
  type error = [ `Msg of string ]

  let make_endpoint (user_id : string) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/users/" ^ user_id
    ^ "/playlists"

  let to_http ?options:_ input =
    let body = Http.Body.of_yojson @@ input_to_yojson input in
    (`POST, Http.Header.empty, make_endpoint input.user_id, body)

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
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

module Get_featured = Spotify_request.Make (struct
  type input = Get_featured_input.t
  type output = Get_featured_output.t
  type error = [ `Msg of string ]

  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"

  let make_endpoint input =
    Http.Uri.add_query_params' base_endpoint
    @@ Get_featured_input.to_query_params input

  let to_http input =
    (`GET, Http.Header.empty, make_endpoint input, Http.Body.empty)

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match Get_featured_output.of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end)

let get_featured = Get_featured.request

module Get_by_id_input = struct
  type t = {
    id : string;
    additional_types : [ `Track | `Episode ] option;
        (* TODO: Figure out if this is a list *)
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
            (fun resource_type -> Resource.to_string resource_type)
            additional_types );
      ]

  let make ?additional_types ?fields ?market id =
    { id; additional_types; fields; market }
end

module Get_by_id_output = struct
  type nonrec t = t
end

module Get_playlist_by_id = Spotify_request.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t
  type error = [ `Msg of string ]

  let make_endpoint (input : input) =
    let base_endpoint =
      Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params input

  let to_http input =
    (`GET, Http.Header.empty, make_endpoint input, Http.Body.empty)

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end)

let get_by_id = Get_playlist_by_id.request
