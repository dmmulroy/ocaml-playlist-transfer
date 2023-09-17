[@@@ocaml.warning "-32"]

open Syntax
open Let

let test_spotify () =
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
  let get_by_id_input = Spotify.Playlist.Get_by_id_input.make ~id () in
  let* spotify_playlist = Spotify.Playlist.get_by_id ~client get_by_id_input in
  let _ =
    match spotify_playlist with
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

let test_apple_get_playlist_by_id () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let client = Apple.Client.make ~jwt ~music_user_token in
  let input =
    Apple.Library_playlist.Get_by_id_input.make
      ~relationships:[ `Tracks; `Catalog ] ~id:"p.PkxV8pzCPa467ad" ()
  in
  let+ playlist = Apple.Library_playlist.get_by_id ~client input in
  let json = Apple.Library_playlist.Get_by_id_output.to_yojson playlist in
  print_endline @@ "Playlists: " ^ Yojson.Safe.pretty_to_string json;
  Lwt.return_ok ()

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

let test_transfer_from_spotify_to_apple id () =
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
  let spotify_client =
    Spotify.Client.make ~access_token ~client_id ~client_secret
  in
  let get_by_id_input = Spotify.Playlist.Get_by_id_input.make ~id () in
  let+ spotify_playlist =
    Spotify.Playlist.get_by_id ~client:spotify_client get_by_id_input
  in
  let+ transfer_playlist, _ =
    Transfer.Playlist.of_spotify spotify_client spotify_playlist
  in
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let jwt_str = Sys.getenv "APPLE_JWT" in
  let| jwt = Apple.Jwt.of_string ~private_pem jwt_str in
  let apple_client = Apple.Client.make ~jwt ~music_user_token in
  let+ _ = Transfer.Playlist.to_apple apple_client transfer_playlist in
  Lwt.return_ok ()

(* type song = { id : string; name : string } *)
(* [@@deriving yojson { exn = true }, show] *)
open Apple.Song.Get_many_by_isrcs_output

let isrc_of_yojson = function
  | `Assoc list ->
      Ok
        (List.map
           (fun (key, json) ->
             match json with
             | `List playlists ->
                 (key, List.map isrc_response_of_yojson playlists)
             | _ -> failwith "expected list of playlists")
           list)
  | _ -> Error "expected key-value pairs"

(* type filters = { isrc : (string * song list) list } [@@deriving yojson, show] *)
(* type meta = { filters : filters } [@@deriving yojson, show] *)
(**)
(* type search_songs_result = { data : song list; meta : meta } *)
(* [@@deriving yojson, show] *)

let my_songs =
  [ ("1", [ { id = "1" }; { id = "2" } ]); ("2", [ { id = "2" } ]) ]

let filters = { isrc = my_songs }
let meta = { filters }

let search_songs_result : Apple.Song.Get_many_by_isrcs_output.t =
  { data = []; meta }

let test_yojson () =
  (* let json = search_songs_result_to_yojson search_songs_result in *)
  let json = to_yojson search_songs_result in
  let res = of_yojson json in
  match res with
  | Ok song_res -> show song_res |> print_endline
  | Error err -> print_endline @@ "Error: " ^ err

(* let () = test_yojson () *)
let () =
  let res =
    Lwt_main.run
    @@ test_transfer_from_spotify_to_apple "2rpDgSpEidno3A0O3tBdfO" ()
  in
  match res with
  | Ok () -> print_endline "Success"
  | Error err -> print_endline @@ Error.to_string err
