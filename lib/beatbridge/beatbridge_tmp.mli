module Client = Client
module Error = Shared.Error

type transfer_report = Transfer_report.t

val make :
  apple_client:Apple.Client.t -> spotify_client:Spotify.Client.t -> Client.t

val make_apple_client :
  developer_token:string ->
  music_user_token:string ->
  (Apple.Client.t, Error.t) result

val make_spotify_client :
  access_token:string -> (Spotify.Client.t, Error.t) result

type platform = Apple | Spotify

val transfer :
  client:Client.t ->
  source:platform ->
  destination:platform ->
  string ->
  (transfer_report, [> `Msg of string ]) Lwt_result.t
