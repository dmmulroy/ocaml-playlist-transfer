let _ =
  print_newline ();
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let access_token_promise =
    match%lwt
      Spotify.Authorization.fetch_access_token ~client_id ~client_secret
    with
    | Ok access_token -> Lwt.return access_token
    | Error err -> Lwt.fail_with @@ Spotify.Error.to_human_string err
  in
  let token = Lwt_main.run access_token_promise in
  print_endline @@ "Access token: "
  ^ Spotify.Authorization.Access_token.show token
