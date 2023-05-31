let base_uri = Uri.of_string "https://accounts.spotify.com/authorize"

let () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let scope = "playlist-read-private" in
  let state = Int.to_string @@ Random.bits () in
  let config = Spotify.Config.make ~client_id ~client_secret () in
  let uri =
    Uri.with_query' base_uri
      [
        ("client_id", Spotify.Config.get_client_id config);
        ("response_type", "code");
        ("redirect_uri", Uri.to_string @@ Spotify.Config.get_redirect_uri config);
        ("scope", scope);
        ("state", state);
      ]
  in
  let cmd = Filename.quote_command "open" [ Uri.to_string uri ] in
  let _ = Unix.system cmd in
  ()
