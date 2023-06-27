type track_or_episode = [ `Track of Track.t | `Episode of Episode.t ]
[@@deriving yojson]

let track_or_episode_of_yojson = function
  | `Assoc key_value_pairs -> (
      let ( >>= ) = Result.bind in
      match List.assoc_opt "type" key_value_pairs with
      | Some (`String "track") ->
          Track.of_yojson @@ `Assoc key_value_pairs >>= fun track ->
          Ok (`Track track)
      | Some (`String "episode") ->
          Episode.of_yojson @@ `Assoc key_value_pairs >>= fun episode ->
          Ok (`Episode episode)
      | _ -> Error "Invalid track_or_episode, missing type field")
  | _ -> Error "Invalid track_or_episode"

let track_or_episode_to_yojson = function
  | `Track track -> Track.to_yojson track
  | `Episode episode -> Episode.to_yojson episode

type video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : track_or_episode;
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

type create_options = {
  public : bool option;
  collaborative : bool option;
  description : string option;
}

type create_request = {
  name : string;
  public : bool option;
  collaborative : bool option;
  description : string option;
}
[@@deriving yojson]

type get_by_id_options = {
  fields : string option;
  market : string option;
  additional_types : [ `Track | `Episode ] option;
}

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

type get_current_users_playlists_options = {
  limit : int option;
  offset : int option;
}

let query_params_of_request_options = function
  | `Get_playlist (Some options) ->
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
  | `Get_current_users_playlists (Some options) ->
      List.filter_map
        (fun (key, value) -> Option.map (fun value -> (key, value)) value)
        [
          ("limit", Option.map string_of_int options.limit);
          ("offset", Option.map string_of_int options.offset);
        ]
  | _ -> []

let create ~(client : Client.t) ~(user_id : string) ~(name : string)
    ?(options : create_options option = None) () =
  let endpoint =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/users/" ^ user_id
    ^ "/playlists"
  in
  let headers =
    Http.Header.of_list
      [
        ("Authorization", Client.get_bearer_token client);
        ("Content-Type", "application/json");
      ]
  in
  let body =
    Http.Body.of_yojson @@ create_request_to_yojson
    @@
    match options with
    | Some { public; collaborative; description } ->
        { name; public; collaborative; description }
    | None -> { name; public = None; collaborative = None; description = None }
  in
  match%lwt Http.Client.post ~headers ~body endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_yojson body in
      match of_yojson json with
      | Ok response -> Lwt.return_ok response
      | Error err -> Lwt.return_error (`Msg err))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))

let get_by_id ~(client : Client.t) (playlist_id : string) ?(options = None) () =
  let base_endpoint =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ playlist_id
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params = query_params_of_request_options @@ `Get_playlist options in
  let endpoint = Http.Uri.add_query_params' base_endpoint query_params in
  match%lwt Http.Client.get ~headers endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_yojson body in
      match of_yojson json with
      | Ok response -> Lwt.return_ok response
      | Error err -> Lwt.return_error (`Msg err))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))

type get_featured_response = {
  message : string;
  playlists : Simple_playlist.t Page.t;
}
[@@deriving yojson]

let get_featured ~(client : Client.t) ?(options = None) () =
  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params =
    query_params_of_request_options @@ `Get_featured_playlists options
  in
  let endpoint = Http.Uri.add_query_params' base_endpoint query_params in
  match%lwt Http.Client.get ~headers endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_yojson body in
      match get_featured_response_of_yojson json with
      | Ok response -> Lwt.return_ok response
      | Error err -> Lwt.return_error (`Msg err))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))

module Me = struct
  type get_current_users_playlists_response = Simple_playlist.t Page.t
  [@@deriving yojson]

  let get_all ~(client : Client.t) ?(options = None) () =
    let base_endpoint =
      Http.Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let headers =
      Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
    in
    let query_params =
      query_params_of_request_options @@ `Get_current_users_playlists options
    in
    let endpoint = Http.Uri.add_query_params' base_endpoint query_params in
    match%lwt Http.Client.get ~headers endpoint with
    | res, body
      when Http.Code.is_success @@ Http.Code.code_of_status
           @@ Http.Response.status res -> (
        let%lwt json = Http.Body.to_yojson body in
        match get_current_users_playlists_response_of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end
