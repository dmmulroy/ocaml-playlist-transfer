module Client = Client

val make :
  apple_client:Apple.Client.t -> spotify_client:Spotify.Client.t -> Client.t

val make_apple_client :
  developer_token:string ->
  music_user_token:string ->
  (Apple.Client.t, Shared.Error.t) result

val make_spotify_client :
  access_token:string -> (Spotify.Client.t, Shared.Error.t) result
