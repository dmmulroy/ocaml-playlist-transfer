open Shared
open Syntax
open Let

let make_client () =
  let developer_token = Sys.getenv "APPLE_DEVELOPER_TOKEN" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let@ apple_client =
    Songstorm.make_apple_client ~developer_token ~music_user_token
  in
  let access_token = Sys.getenv "SPOTIFY_ACCESS_TOKEN" in
  let@ spotify_client = Songstorm.make_spotify_client ~access_token in
  let songstorm_client = Songstorm.make ~apple_client ~spotify_client in
  Ok songstorm_client

let main () =
  let@ client = make_client () in
  let _ =
    Songstorm.transfer ~client ~source:Apple ~destination:Spotify "playlist_id"
  in

  Ok ()
