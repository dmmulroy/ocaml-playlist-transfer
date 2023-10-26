let make_apple_client = Apple.Client.make

let make_spotify_client ~access_token =
  Spotify.Client.make ~access_token:(`String access_token) |> Result.ok
