type t = { apple_client : Apple.Client.t; spotify_client : Spotify.Client.t }

let make ~apple_client ~spotify_client = { apple_client; spotify_client }
