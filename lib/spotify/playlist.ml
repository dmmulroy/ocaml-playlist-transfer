type video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : Track.t;
  video_thumbnail : video_thumbnail option; [@default None]
}
[@@deriving yojson]

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

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

type get_playlist_by_id_options = {
  fields : string option;
  market : string option;
  additional_types : [ `Track | `Episode ] option;
}

let query_params_of_request_options = function
  | `Get_playlist options ->
      List.filter_map
        (fun (key, value) -> Option.map (fun value -> (key, value)) value)
        [
          ("fields", options.fields);
          ("market", options.market);
          ( "additional_types",
            Option.map
              (fun resource_type ->
                match resource_type with
                | `Track -> "track"
                | `Episode -> "episode")
              options.additional_types );
        ]
  | `Get_featured_playlists (Some options) ->
      List.filter_map
        (fun (key, value) -> Option.map (fun value -> (key, value)) value)
        [
          ("country", options.country);
          ("locale", options.locale);
          ("timestamp", options.timestamp);
          ("limit", Option.map string_of_int options.limit);
          ("offset", Option.map string_of_int options.offset);
        ]
  | _ -> []

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

  let to_http ?options input =
    let body = Http.Body.of_yojson @@ input_to_yojson input in
    match options with
    | _ -> (`POST, Http.Header.empty, make_endpoint input.user_id, body)

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

type get_featured_response = {
  message : string;
  playlists : Simple_playlist.t Page.t;
}
[@@deriving yojson]

module GetFeaturePlaylists = Spotify_request.Make (struct
  type input = unit
  type options = get_featured_playlists_options
  type output = get_featured_response
  type error = [ `Msg of string ]

  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"

  let make_endpoint options =
    Http.Uri.add_query_params' base_endpoint
      (query_params_of_request_options @@ `Get_featured_playlists options)

  let to_http ?options _ =
    (`GET, Http.Header.empty, make_endpoint options, Http.Body.empty)

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match get_featured_response_of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end)

let get_featured = GetFeaturePlaylists.request

module GetPlaylistById = Spotify_request.Make (struct
  type input = string
  type options = get_playlist_by_id_options
  type output = t
  type error = [ `Msg of string ]

  let make_endpoint id =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ id

  let to_http ?options playlist_id =
    match options with
    | None ->
        (`GET, Http.Header.init (), make_endpoint playlist_id, Http.Body.empty)
    | Some options ->
        let query_params =
          query_params_of_request_options @@ `Get_playlist options
        in
        let endpoint =
          Http.Uri.add_query_params' (make_endpoint playlist_id) query_params
        in
        (`GET, Http.Header.init (), endpoint, Http.Body.empty)

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

let get_by_id = GetPlaylistById.request
