[@@@ocaml.warning "-27"]

module Client = Client
module Error = Shared.Error

type transfer_report = Transfer_report.t
type platform = Apple | Spotify

let make = Client.make
let make_apple_client = Auth.make_apple_client
let make_spotify_client = Auth.make_spotify_client

let transfer_from_apple_to_spotify ~client playlist_id =
  failwith "not implemented"

let transfer_from_spotify_to_apple ~client playlist_id =
  failwith "not implemented"

let transfer ~client ~source ~destination playlist_id =
  match (source, destination) with
  | Spotify, Apple -> transfer_from_spotify_to_apple ~client playlist_id
  | Apple, Spotify -> transfer_from_apple_to_spotify ~client playlist_id
  | Apple, Apple -> Lwt.return_error (`Msg "no op")
  | Spotify, Spotify -> Lwt.return_error (`Msg "no op")
