module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

type get_featured_playlists_request = {
  country : string;
  locale : string;
  timestamp : string;
  limit : int;
  offset : int;
}

let get_featured_playlists (client : Client.t) =
  let endpoint =
    Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
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
