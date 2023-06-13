let tracks_of_yojson json =
  match Yojson.Safe.Util.member "items" json with
  | exception Yojson.Safe.Util.Type_error _ -> (
      match
        ( Yojson.Safe.Util.member "href" json,
          Yojson.Safe.Util.member "total" json )
      with
      | `String _, `Int _ -> (
          match Resource_type.reference_of_yojson json with
          | Error _ ->
              Error
                "Playlist tracks reference response is missing required fields"
          | Ok reference -> Ok (`Resource_reference reference))
      | _ ->
          Error "Playlist tracks reference response is missing required fields")
  | _ -> (
      match Paginated_response.of_yojson Track.of_yojson json with
      | Error _ -> Error "Playlist tracks response is missing required fields"
      | Ok tracks -> Ok (`Tracks tracks))

type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; [@default None] (* nullable *)
  href : string;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  public : bool option;
  resource_type : [ `Playlist ];
      [@key "type"]
      [@of_yojson Resource_type.playlist_of_yojson]
      [@to_yojson Resource_type.playlist_to_yojson]
  snapshot_id : string;
  tracks :
    [ `Resource_reference of Resource_type.reference
    | `Tracks of Track.t Paginated_response.t ];
      [@of_yojson tracks_of_yojson]
  uri : string;
}
[@@deriving yojson { strict = false }]

type get_playlist_options = {
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
  | `Get_current_users_playlists_options (Some options) ->
      List.filter_map
        (fun (key, value) -> Option.map (fun value -> (key, value)) value)
        [
          ("limit", Option.map string_of_int options.limit);
          ("offset", Option.map string_of_int options.offset);
        ]
  | _ -> []

let get_playlist (client : Client.t) (playlist_id : string) ?(options = None) ()
    =
  let base_endpoint =
    Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ playlist_id
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params = query_params_of_request_options @@ `Get_playlist options in
  let endpoint = Uri.add_query_params' base_endpoint query_params in
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

type get_featured_playlists_response = {
  message : string;
  playlists : t Paginated_response.t;
}
[@@deriving yojson]

let get_featured_playlists (client : Client.t) ?(options = None) () =
  let base_endpoint =
    Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params =
    query_params_of_request_options @@ `Get_featured_playlists options
  in
  let endpoint = Uri.add_query_params' base_endpoint query_params in
  match%lwt Http.Client.get ~headers endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_yojson body in
      match get_featured_playlists_response_of_yojson json with
      | Ok response ->
          Lwt.return_ok @@ Paginated_response.get_items response.playlists
      | Error err -> Lwt.return_error (`Msg err))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))

module Me = struct
  type get_current_users_playlists_response = t Paginated_response.t
  [@@deriving yojson]

  let get_playlists (client : Client.t) ?(options = None) () =
    let base_endpoint =
      Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let headers =
      Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
    in
    let query_params =
      query_params_of_request_options @@ `Get_current_users_playlists options
    in
    let endpoint = Uri.add_query_params' base_endpoint query_params in
    match%lwt Http.Client.get ~headers endpoint with
    | res, body
      when Http.Code.is_success @@ Http.Code.code_of_status
           @@ Http.Response.status res -> (
        let%lwt json = Http.Body.to_yojson body in
        match get_current_users_playlists_response_of_yojson json with
        | Ok response -> Lwt.return_ok @@ Paginated_response.get_items response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end
