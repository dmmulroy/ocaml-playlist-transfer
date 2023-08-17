[@@@ocaml.warning "-32"]

open Syntax
open Let

let test_spotify () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let state = Int.to_string @@ Random.bits () in
  let redirect_uri = Http.Uri.of_string "http://localhost:3939/spotify" in
  let redirect_server = Http.Redirect_server.make ~state ~redirect_uri in
  let* _ = Http.Redirect_server.run redirect_server () in
  let authorization_uri =
    Spotify.Auth.make_authorization_url ~client_id ~redirect_uri ~state
      ~scopes:
        [
          `Playlist_read_private;
          `Playlist_modify_public;
          `Playlist_modify_private;
        ]
      ~show_dialog:false ()
  in
  let cmd = Filename.quote_command "open" [ Uri.to_string authorization_uri ] in
  let _ = Unix.system cmd in
  let* code = Http.Redirect_server.get_code redirect_server in
  let+ access_token =
    Spotify.Auth.request_access_token
      (`Authorization_code { client_secret; client_id; code; redirect_uri })
  in
  let client = Spotify.Client.make ~access_token ~client_id ~client_secret in
  let get_by_id_input =
    Spotify.Playlist.Get_by_id_input.make ~id:"37i9dQZF1DXcBWIGoYBM5M" ()
  in
  let* playlist_result = Spotify.Playlist.get_by_id ~client get_by_id_input in
  let _ =
    match playlist_result with
    | Error err -> print_endline @@ Error.to_string err
    | Ok playlist ->
        print_endline @@ "Playlist: " ^ playlist.name;
        let () =
          List.iteri
            (fun idx playlist_track ->
              Spotify.Playlist.(
                print_endline @@ string_of_int idx ^ ": "
                ^ playlist_track.track.name))
            playlist.tracks.items
        in
        ()
  in
  Lwt.return_ok ()

let test_apple () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let team_id = Sys.getenv "APPLE_TEAM_ID" in
  let key_id = Sys.getenv "APPLE_KEY_ID" in
  let| jwt = Apple.Auth.Jwt.make ~private_pem ~team_id ~key_id () in
  let validated_jwt_res = Apple.Auth.Jwt.validate jwt in
  let _ =
    match validated_jwt_res with
    | Error err ->
        print_endline @@ Error.to_string err;
        failwith "failed"
    | Ok jwt ->
        print_endline @@ "successfully validated: "
        ^ Apple.Auth.Jwt.to_string jwt
  in
  let* test_res = Apple.Auth.test_auth jwt in
  let _ =
    match test_res with
    | Error err -> print_endline @@ Error.to_string err
    | Ok _ -> print_endline "success"
  in
  Lwt.return_ok ()

let () =
  let _ = Lwt_main.run @@ test_apple () in
  ()
