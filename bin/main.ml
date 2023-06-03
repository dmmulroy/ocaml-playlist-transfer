let () =
  print_newline ();
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let access_token_promise =
    match%lwt
      Spotify.Authorization.fetch_access_token ~client_id ~client_secret
    with
    | Ok access_token ->
        Lwt.return @@ print_endline @@ "success: "
        ^ Spotify.Authorization.Access_token.show access_token
    | Error err -> Lwt.return @@ print_endline ("error: " ^ err)
  in
  Lwt_main.run access_token_promise
