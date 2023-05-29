open Services

let () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let spotify_client = Lwt_main.run @@ Spotify.init ~client_id ~client_secret in
  print_string spotify_client.access_token
