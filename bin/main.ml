let () =
  print_newline ();
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let main =
    let state = Int.to_string @@ Random.bits () in
    let redirect_uri = Uri.of_string "http://localhost:3939/spotify" in
    let redirect_server = Http.Redirect_server.make ~state ~redirect_uri in
    let%lwt _ = Http.Redirect_server.run redirect_server () in
    let authorization_uri =
      Spotify.Authorization.make_authorization_url
        {
          client_id;
          client_secret;
          redirect_uri;
          state;
          scopes = Some [ `Playlist_read_private ];
          show_dialog = true;
        }
    in
    let cmd =
      Filename.quote_command "open" [ Uri.to_string authorization_uri ]
    in
    let _ = Unix.system cmd in
    let%lwt code = Http.Redirect_server.get_code redirect_server in
    let%lwt access_token =
      match%lwt
        Spotify.Authorization.fetch_access_token
        @@ `Authorization_code { client_secret; client_id; code; redirect_uri }
      with
      | Ok access_token -> Lwt.return access_token
      | Error err -> Lwt.fail_with @@ Spotify.Error.to_human_string err
    in

    (* print_endline @@ Spotify.Authorization.Access_token.show access_token; *)
    let spotify = Spotify.Client.make access_token in
    let%lwt response = Spotify.Playlist.Me.get_playlists spotify () in
    match response with
    | Ok featured_playlists ->
        List.iter
          (fun playlist ->
            let open Spotify.Playlist in
            Printf.printf "%s\n" playlist.name)
          featured_playlists;
        Lwt.return_unit
    | Error (`Msg err) -> Lwt.return @@ print_endline ("err: " ^ err)
  in
  Lwt_main.run main
