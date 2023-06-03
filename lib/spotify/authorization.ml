type t = { config : Config.t }
type error = [ `Msg of string ]

let base_authorization_uri =
  Uri.of_string "https://accounts.spotify.com/authorize"

let open_authorization_uri (uri : Uri.t) =
  let cmd = Filename.quote_command "open" [ Uri.to_string uri ] in
  let _ = Unix.system cmd in
  ()

let make (config : Config.t) = { config }

let authorization_code_grant t : (string, error) result Lwt.t =
  let redirect_uri = Config.get_redirect_uri t.config in
  let state = Int.to_string @@ Random.bits () in
  let authorization_uri =
    Uri.with_query' base_authorization_uri
      [
        ("client_id", Config.get_client_id t.config);
        ("response_type", "code");
        ("redirect_uri", Uri.to_string redirect_uri);
        ("scope", "playlist-read-private");
        ("state", state);
      ]
  in
  let server = Redirect_server.make ~redirect_uri ~state in
  let _ = Redirect_server.run server () in
  let () = open_authorization_uri authorization_uri in
  let%lwt code = Redirect_server.get_code server in
  Lwt.return_ok code
