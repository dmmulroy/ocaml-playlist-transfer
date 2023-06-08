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
    let spotify = Spotify.Client.make access_token in
    let%lwt result = Spotify.Playlist.get_featured_playlists spotify () in
    match result with
    | Ok paginated_playlists ->
        List.iter
          (fun playlist -> Printf.printf "%s\n" playlist.Spotify.Playlist.name)
          paginated_playlists.playlists.items;
        Lwt.return_unit
    | Error (`Msg err) -> Lwt.return @@ print_endline ("err: " ^ err)
  in
  Lwt_main.run main
