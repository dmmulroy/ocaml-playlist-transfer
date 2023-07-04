type get_current_users_playlists_options = {
  limit : int option;
  offset : int option;
}

let query_params_of_request_options = function
  | `Get_current_users_playlists (Some options) ->
      List.filter_map
        (fun (key, value) -> Option.map (fun value -> (key, value)) value)
        [
          ("limit", Option.map string_of_int options.limit);
          ("offset", Option.map string_of_int options.offset);
        ]
  | _ -> []

module Me = struct
  type get_current_users_playlists_response = Simple_playlist.t Page.t
  [@@deriving yojson]

  let get_all ?options ~(client : Client.t) () =
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
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match get_current_users_playlists_response_of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end
