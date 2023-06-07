module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

let query_params_of_reuest_options = function
  | `Get_featured_playlists -> (
      function
      | None -> []
      | Some options ->
          List.filter_map
            (fun (key, value) -> Option.map (fun value -> (key, value)) value)
            [
              ("country", options.country);
              ("locale", options.locale);
              ("timestamp", options.timestamp);
              ("limit", Option.map string_of_int options.limit);
              ("offset", Option.map string_of_int options.offset);
            ])

let get_featured_playlists (client : Client.t) ?(options = None) () =
  let base_endpoint =
    Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params =
    query_params_of_reuest_options `Get_featured_playlists options
  in
  let endpoint = Uri.add_query_params' base_endpoint query_params in
  match%lwt Http.Client.get ~headers endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res ->
      let%lwt json = Cohttp_lwt.Body.to_string body in
      print_endline ("Success: " ^ json);
      Lwt.return_ok ()
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      print_endline ("Error: " ^ Http.Code.string_of_status status_code ^ json);
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
