[@@@ocaml.warning "-27"]

open Shared
open Syntax
open Let

module Add_tracks = struct
  type input = { playlist_id : string; uris : string list }

  let input_to_yojson { uris; _ } =
    `Assoc [ ("uris", `List (List.map (fun uri -> `String uri) uris)) ]

  type output = { snapshot_id : string } [@@deriving yojson]

  let name = "Add_tracks"

  let make_endpoint (playlist_id : string) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ playlist_id
    ^ "/tracks"

  let to_http_request input =
    let open Infix.Result in
    let input_json = input_to_yojson input in
    let| body =
      input |> input_to_yojson |> Http.Body.of_yojson >|? fun str ->
      Spotify_error.make ~source:(`Serialization (`Json input_json)) str
    in
    Lwt.return_ok
    @@ Http.Request.make ~meth:`POST ~body
         ~uri:(make_endpoint input.playlist_id)
         ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let add_tracks ~client ~track_uris playlist_id =
  let module Request = Spotify_rest_client.Make (Add_tracks) in
  Request.request ~client { playlist_id; uris = track_uris }
  |> Lwt_result.map Spotify_rest_client.Response.make

module CreatePlaylist = struct
  let name = "Create_playlist"

  type input = {
    collaborative : bool option;
    description : string option;
    name : string;
    public : bool option;
    user_id : string;
  }

  type output = Types.Playlist.t [@@deriving yojson]
  type body = { name : string } [@@deriving yojson]

  let make_endpoint user_id =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/users/" ^ user_id
    ^ "/playlists"

  let to_http_request (input : input) =
    let open Infix.Result in
    let input_json = body_to_yojson { name = input.name } in
    let| body =
      Http.Body.of_yojson input_json >|? fun str ->
      Spotify_error.make ~source:(`Serialization (`Json input_json)) str
    in
    Lwt.return_ok
    @@ Http.Request.make ~meth:`POST ~body ~uri:(make_endpoint input.user_id) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let create ~client ?collaborative ?description ?public ~name ~user_id () =
  let module Request = Spotify_rest_client.Make (CreatePlaylist) in
  Request.request ~client { collaborative; description; name; public; user_id }
  |> Lwt_result.map Spotify_rest_client.Response.make

module Get_featured = struct
  let name = "Get_featured"

  type input = {
    country : string option;
    locale : string option;
    timestamp : string option;
    limit : int option;
    offset : int option;
  }

  type output = { message : string; playlists : Types.Simple_playlist.t Page.t }
  [@@deriving yojson]

  let input_to_query_params { country; locale; timestamp; limit; offset } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("country", country);
        ("locale", locale);
        ("timestamp", timestamp);
        ("limit", Option.map string_of_int limit);
        ("offset", Option.map string_of_int offset);
      ]

  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"

  let make_endpoint input =
    Http.Uri.add_query_params' base_endpoint @@ input_to_query_params input

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_featured ~client ?country ?locale ?timestamp ?limit ?offset () =
  let module Request = Spotify_rest_client.Make (Get_featured) in
  Request.request ~client { country; locale; timestamp; limit; offset }
  |> Lwt_result.map Spotify_rest_client.Response.make

module Get_by_id = struct
  let name = "Get_by_id"

  type input = {
    id : string;
    additional_types : [ `Track | `Episode ] list option;
    fields : string option;
    market : string option;
  }

  type output = Types.Playlist.t [@@deriving yojson]

  let input_to_query_params { additional_types; fields; market; _ } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("fields", fields);
        ("market", market);
        ( "additional_types",
          Option.map
            (fun additional_types' ->
              additional_types'
              |> List.map Resource.to_string
              |> String.concat ",")
            additional_types );
      ]

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ input.id
    in
    Http.Uri.add_query_params' base_endpoint @@ input_to_query_params input

  let to_http_request (request : input) =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint request) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_by_id ~client ?additional_types ?field ?market id =
  let module Request = Spotify_rest_client.Make (Get_by_id) in
  Request.request ~client { id; additional_types; fields = field; market }
  |> Lwt_result.map Spotify_rest_client.Response.make

module Get_tracks_by_id = struct
  let name = "Get_tracks_by_id"

  (* TODO: Finish adding API Params *)
  type input = { playlist_id : string; limit : int option; offset : int option }
  type output = Types.Playlist.playlist_track Page.t [@@deriving yojson]

  let input_to_query_params (input : input) =
    [
      ("limit", Option.map string_of_int input.limit);
      ("offset", Option.map string_of_int input.offset);
    ]
    |> List.filter_map (fun (key, value) ->
           Option.map (fun value' -> (key, value')) value)

  let make_endpoint input =
    let endpoint =
      Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/"
      ^ input.playlist_id ^ "/tracks"
    in
    Http.Uri.with_query' endpoint (input_to_query_params input)

  let to_http_request input =
    let uri = make_endpoint input in
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_tracks_by_id ~client
    ?(page :
       [ `Next of Types.Playlist.playlist_track Page.t
       | `Previous of Types.Playlist.playlist_track Page.t ]
       option) playlist_id =
  let module Request = Spotify_rest_client.Make (Get_tracks_by_id) in
  let open Get_tracks_by_id in
  let open Page in
  let module Request = Spotify_rest_client.Make (Get_tracks_by_id) in
  let limit, offset =
    match page with
    | None -> (None, None)
    | Some (`Next page) ->
        Page.next_limit_and_offset page
        |> Option.fold ~none:(None, None) ~some:(fun (limit, offset) ->
               (limit, offset))
    | Some (`Previous page) ->
        Page.previous_limit_and_offset page
        |> Option.fold ~none:(None, None) ~some:(fun (limit, offset) ->
               (limit, offset))
  in
  let request = { playlist_id; limit; offset } in
  let+ playlist_track_page = Request.request ~client request in
  let pagination = Spotify_rest_client.pagination_of_page playlist_track_page in
  Lwt.return_ok
  @@ Spotify_rest_client.Response.Paginated.make pagination
       playlist_track_page.items
