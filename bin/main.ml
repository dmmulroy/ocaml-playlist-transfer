(* Potentailly ignore some warnings in dune profiles *)
[@@@ocaml.warning "-32-33-27"]

open Shared
open Syntax
open Let

let make_spotify_client () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let state = Int.to_string @@ Random.bits () in
  let redirect_uri = Http.Uri.of_string "http://localhost:3939/spotify" in
  let redirect_server = Redirect_server.make ~state ~redirect_uri in
  let* _ = Redirect_server.run redirect_server () in
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
  let cmd =
    Filename.quote_command "open" [ Http.Uri.to_string authorization_uri ]
  in
  let _ = Unix.system cmd in
  let* code = Redirect_server.get_code redirect_server in
  let+ access_token =
    Spotify.Auth.request_access_token
      (`Authorization_code { client_secret; client_id; code; redirect_uri })
  in
  Lwt.return_ok @@ Spotify.Client.make ~access_token ~client_id ~client_secret

let make_apple_client () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  Lwt.return_ok @@ Apple.Client.make ~jwt ~music_user_token

let test_spotify_oauth () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let state = Int.to_string @@ Random.bits () in
  let redirect_uri = Http.Uri.of_string "http://localhost:3939/spotify" in
  let redirect_server = Redirect_server.make ~state ~redirect_uri in
  let* _ = Redirect_server.run redirect_server () in
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
  let cmd =
    Filename.quote_command "open" [ Http.Uri.to_string authorization_uri ]
  in
  let _ = Unix.system cmd in
  let* code = Redirect_server.get_code redirect_server in
  let+ access_token =
    Spotify.Auth.request_access_token
      (`Authorization_code { client_secret; client_id; code; redirect_uri })
  in
  let client = Spotify.Client.make ~access_token ~client_id ~client_secret in
  let request =
    Spotify.Playlist.Get_by_id_input.make ~id:"37i9dQZF1F0sijgNaJdgit" ()
  in
  let* playlist_result = Spotify.Playlist.get_by_id ~client request in
  let _ =
    match playlist_result with
    | Error err -> print_endline @@ Error.to_string err
    | Ok { data = playlist; _ } ->
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

let test_get_spotify_playlist_by_id id () =
  let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in
  let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in
  let access_token_str = Sys.getenv "SPOTIFY_ACCESS_TOKEN" in
  let access_token =
    Spotify.Access_token.make
      ~scopes:
        [
          `Playlist_read_private;
          `Playlist_modify_public;
          `Playlist_modify_private;
        ]
      ~expiration_time:((Int.of_float @@ Unix.time ()) + 3600)
      ~grant_type:`Authorization_code ~token:access_token_str ()
  in
  let client = Spotify.Client.make ~access_token ~client_id ~client_secret in
  let request = Spotify.Playlist.Get_by_id_input.make ~id () in
  let+ response = Spotify.Playlist.get_by_id ~client request in
  Lwt.return_ok response.data

let fetch_all_spotify_playlist_tracks ~client id =
  let open Spotify.Spotify_rest_client.Pagination in
  let request = Spotify.Playlist.Get_tracks_input.make id in
  let+ response = Spotify.Playlist.get_tracks ~client request in
  let fetch_all_tracks ~client request tracks page =
    let rec aux acc = function
      | None -> Lwt.return_ok acc
      | Some next ->
          let+ { data; page = page' } =
            Spotify.Playlist.get_tracks ~client
              { request with page = Some next }
          in
          aux (List.append data.items acc) page'.next
    in
    aux tracks page.next
  in
  fetch_all_tracks ~client request response.data.items response.page

let fetch_all_spotify_search_results ~client isrc_ids =
  let open Spotify.Spotify_rest_client.Pagination in
  let request =
    Spotify.Search.Search_input.make ~limit:50 ~query:isrc_ids
      ~search_types:[ `Track ] ()
  in
  let+ response = Spotify.Search.search ~client request in
  let fetch_all_results ~client request results page =
    let rec aux acc = function
      | None -> Lwt.return_ok acc
      | Some next -> (
          let+ { data; page = page' } =
            Spotify.Search.search ~client { request with page = Some next }
          in
          match data.tracks with
          | None -> aux acc None
          | Some tracks_page ->
              aux (List.append tracks_page.items acc) page'.next)
    in
    aux results page.next
  in
  match response.data.tracks with
  | None -> Lwt.return_ok []
  | Some tracks_page ->
      fetch_all_results ~client request tracks_page.items response.page

let test_get_spotify_playlist_tracks playlist_id =
  let+ client = make_spotify_client () in
  let+ response = fetch_all_spotify_playlist_tracks ~client playlist_id in
  print_endline "Playlist tracks:";
  List.iteri
    (fun idx playlist_track ->
      let open Spotify.Playlist in
      print_endline @@ string_of_int idx ^ ": " ^ playlist_track.track.name)
    response;
  Lwt.return_ok ()

(* let test_search_spotify () = *)
(*   let+ client = make_spotify_client () in *)
(*   let request = *)
(*     Spotify.Search.Search_input.make *)
(*       ~query:[ ("USUM72307683", `Isrc) ] *)
(*       ~search_types:[ `Track ] () *)
(*   in *)
(*   let+ { data; _ } = Spotify.Search.search ~client request in *)
(*   let tracks = Option.get data.tracks in *)
(*   print_endline @@ "Number of tracks found: " ^ Int.to_string tracks.total; *)
(*   Lwt.return_ok () *)

(* let test_apple_Get_by_id () = *)
(*   let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in *)
(*   let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in *)
(*   let jwt_str = Sys.getenv "APPLE_JWT" in *)
(*   let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in *)
(*   let _client = Apple.Client.make ~jwt ~music_user_token in *)
(*   let _input = *)
(*     Apple.Library_playlist.Get_by_id_input.make *)
(*       ~relationships:[ `Tracks; `Catalog ] ~id:"p.PkxV8pzCPa467ad" () *)
(*   in *)
(*   (* let+ playlist = Apple.Library_playlist.get_by_id ~client input in *) *)
(*   (* print_endline @@ "Playlists: " ^ Yojson.Safe.pretty_to_string json; *) *)
(*   Lwt.return_ok () *)

let test_apple_create_playlist () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let client = Apple.Client.make ~jwt ~music_user_token in
  let input =
    Apple.Library_playlist.Create_input.make ~name:"Test"
      ~description:"Test description"
      ~tracks:[ { id = "i.kGO5DkBTdX1lWXa"; resource_type = `Library_songs } ]
      ()
  in
  let+ playlist = Apple.Library_playlist.create ~client input in
  let json = Apple.Library_playlist.Create_output.to_yojson playlist in
  print_endline @@ "Playlist: " ^ Yojson.Safe.pretty_to_string json;
  Lwt.return_ok ()

let test_apple_get_song_by_id () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let client = Apple.Client.make ~jwt ~music_user_token in
  let input = Apple.Song.Get_by_id_input.make "1696596473" in
  let+ result = Apple.Song.get_by_id ~client input in
  print_endline @@ "Song: " ^ Yojson.Safe.pretty_to_string
  @@ Apple.Song.Get_by_id_output.to_yojson result;
  Lwt.return_ok ()

let test_apple_get_song_by_isrcs () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let client = Apple.Client.make ~jwt ~music_user_token in
  let+ _result = Apple.Song.get_many_by_isrcs ~client [ "USUM72102276" ] in
  (* print_endline @@ "Song: " ^ Yojson.Safe.pretty_to_string *)
  (* @@ Apple.Song.Get_many_by_isrcs_output.to_yojson result; *)
  Lwt.return_ok ()

let test_transfer_from_spotify_to_apple playlist_id () =
  let+ spotify_client = make_spotify_client () in
  let request = Spotify.Playlist.Get_by_id_input.make ~id:playlist_id () in
  let+ { data = playlist; _ } =
    Spotify.Playlist.get_by_id ~client:spotify_client request
  in
  let+ spotify_tracks =
    fetch_all_spotify_playlist_tracks ~client:spotify_client playlist_id
  in
  let transfer_tracks, _skipped_tracks =
    List.partition_map
      (fun (playlist_track : Spotify.Playlist.playlist_track) ->
        Transfer.Track.of_spotify playlist_track.track)
      spotify_tracks
  in
  let transfer_playlist =
    Transfer.Playlist.make ~name:playlist.name
      ~description:(Option.value ~default:playlist.name playlist.description)
      ~tracks:transfer_tracks ()
  in
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let apple_client = Apple.Client.make ~jwt ~music_user_token in
  let+ _ = Transfer.Playlist.to_apple apple_client transfer_playlist in
  Lwt.return_ok ()

(* "p.PkxV8pzCPa467ad" *)
let test_transfer_from_apple_to_spotify ~apple_client ~spotify_client
    (playlist_id : string) =
  let request = Apple.Library_playlist.Get_by_id_input.make playlist_id in
  let+ { data; _ } =
    Apple.Library_playlist.get_by_id ~client:apple_client request
  in
  let| playlist =
    data.data |> Extended.List.hd_opt
    |> Option.to_result
         ~none:
           (Apple.Apple_error.make ~source:(`Source "main") "No songs found")
  in
  let tracks_request =
    Apple.Library_playlist.Get_relationship_by_name_input.make ~playlist_id
      ~relationship:`Tracks
  in
  let+ { data = apple_tracks; _ } =
    Apple.Library_playlist.get_relationship_by_name ~client:apple_client
      tracks_request
  in
  let _ : Apple.Library_song.t list = apple_tracks.data in
  (* let transfer_tracks, _skipped_tracks = *)
  (*   List.partition_map *)
  (*     (fun (playlist_track : Spotify.Playlist.playlist_track) -> *)
  (*       Transfer.Track.of_apple playlist_track.track) *)
  (*     apple_tracks.data *)
  (* let transfer_playlist = *)
  (*   Transfer.Playlist.make ~name:playlist.attributes.name *)
  (*     ~description:playlist.attributes.name ~tracks:transfer_tracks () *)
  (* let spotify_tracks = *)
  (*   fetch_all_spotify_search_results ~client:spotify_client *)
  (* in *)
  failwith "Not implemented"

(* let () = *)
(*   let res = Lwt_main.run @@ test_search_spotify () in *)
(*   match res with *)
(*   | Ok _ -> print_endline "Success" *)
(*   | Error err -> Error.to_string err |> print_endline *)
