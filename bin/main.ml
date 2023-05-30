open Services

let () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let init_result = Lwt_main.run @@ Spotify.init ~client_id ~client_secret in
  let spotify =
    match init_result with
    | Ok spotify -> spotify
    | Error (`SpotifyApiError err) -> failwith err
  in
  print_string @@ Spotify.to_string spotify
