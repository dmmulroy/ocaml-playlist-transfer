let () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let main =
    let%lwt access_token =
      match%lwt
        Spotify.Authorization.fetch_access_token ~client_id ~client_secret
      with
      | Ok access_token -> Lwt.return access_token
      | Error err -> Lwt.fail_with @@ Spotify.Error.to_human_string err
    in
    (* print_endline @@ Spotify.Authorization.Access_token.show access_token; *)
    let spotify = Spotify.Client.make access_token in
    let%lwt response = Spotify.Playlist.get_featured_playlists spotify () in
    match response with
    | Ok featured_playlists ->
        print_newline ();
        List.iter
          (fun playlist ->
            let open Spotify.Playlist in
            Printf.printf "%s\n" playlist.name)
          featured_playlists;
        Lwt.return_unit
    | Error (`Msg err) -> Lwt.return @@ print_endline ("err: " ^ err)
  in
  Lwt_main.run main
