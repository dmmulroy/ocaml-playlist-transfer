(* let ( let* ) = Result.bind *)

let _test_spotify () =
  print_newline ();
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let main =
    let state = Int.to_string @@ Random.bits () in
    let redirect_uri = Http.Uri.of_string "http://localhost:3939/spotify" in
    let redirect_server = Http.Redirect_server.make ~state ~redirect_uri in
    let%lwt _ = Http.Redirect_server.run redirect_server () in
    let authorization_uri =
      Spotify.Authorization.make_authorization_url ~client_id ~redirect_uri
        ~state
        ~scopes:
          [
            `Playlist_read_private;
            `Playlist_modify_public;
            `Playlist_modify_private;
          ]
        ~show_dialog:false ()
    in
    let cmd =
      Filename.quote_command "open" [ Uri.to_string authorization_uri ]
    in
    let _ = Unix.system cmd in
    let%lwt code = Http.Redirect_server.get_code redirect_server in
    let%lwt access_token =
      match%lwt
        Spotify.Authorization.request_access_token
          (`Authorization_code { client_secret; client_id; code; redirect_uri })
      with
      | Ok access_token -> Lwt.return access_token
      | Error err -> Lwt.fail_with @@ Spotify.Error.to_string err
    in
    let client = Spotify.Client.make ~access_token ~client_id ~client_secret in
    let get_by_id_input =
      Spotify.Playlist.Get_by_id_input.make ~id:"37i9dQZF1DXcBWIGoYBM5M" ()
    in
    let%lwt response = Spotify.Playlist.get_by_id ~client get_by_id_input in
    match response with
    | Ok playlist ->
        let open Spotify.Playlist in
        print_endline @@ "Playlist: " ^ playlist.name;
        let () =
          List.iteri
            (fun idx playlist_track ->
              print_endline @@ string_of_int idx ^ ": "
              ^ playlist_track.track.name)
            playlist.tracks.items
        in
        Lwt.return_unit
    | Error (`Msg err) -> Lwt.return @@ print_endline ("err: " ^ err)
  in
  Lwt_main.run main

let test_apple () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let team_id = Sys.getenv "APPLE_TEAM_ID" in
  let key_id = Sys.getenv "APPLE_KEY_ID" in
  let jwt_res = Apple.Authorization.Jwt.make ~private_pem ~team_id ~key_id () in
  match jwt_res with
  | Ok jwt -> (
      print_endline @@ Apple.Authorization.Jwt.to_string jwt;
      match%lwt Apple.Authorization.test_authorization jwt with
      | Ok _ -> Lwt.return_unit
      | Error _err -> failwith "failed test auth")
  | Error _err -> failwith "failed making jwt"

let () =
  let () = Lwt_main.run @@ test_apple () in
  ()
