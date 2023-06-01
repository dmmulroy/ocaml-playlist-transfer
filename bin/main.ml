let () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let config = Spotify.Config.make ~client_id ~client_secret () in
  let authorizer = Spotify.Authorization.make config in
  let promise = Spotify.Authorization.authorization_code_grant authorizer in

  let result = Lwt_main.run promise in
  match result with
  | Ok token -> print_endline token
  | Error (`Msg err) -> print_endline err
