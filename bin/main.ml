[@@@ocaml.warning "-26-27-32-33"]

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
  let+ { data = access_token } =
    Spotify.Auth.request_access_token
      (`Authorization_code { client_secret; client_id; code; redirect_uri })
  in
  Lwt.return_ok
  @@ Spotify.Client.make ~access_token:(`Access_token access_token)

let make_apple_client () =
  let private_pem = Sys.getenv "APPLE_PRIVATE_KEY" in
  let music_user_token = Sys.getenv "APPLE_MUSIC_USER_TOKEN" in
  let developer_token = Sys.getenv "APPLE_DEVELOPER_TOKEN" in
  let| client = Apple.Client.make ~developer_token ~music_user_token in
  Lwt.return_ok client

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
  let+ { data = access_token } =
    Spotify.Auth.request_access_token
      (`Authorization_code { client_secret; client_id; code; redirect_uri })
  in
  let client = Spotify.Client.make ~access_token:(`Access_token access_token) in
  let* playlist_result =
    Spotify.Playlist.get_by_id ~client "37i9dQZF1F0sijgNaJdgit"
  in
  let _ =
    match playlist_result with
    | Error err -> print_endline @@ Error.to_string err
    | Ok { data = playlist; _ } ->
        print_endline @@ "Playlist: " ^ playlist.name;
        let () =
          List.iteri
            (fun idx playlist_track ->
              Spotify.Types.Playlist.(
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
  let client = Spotify.Client.make ~access_token:(`Access_token access_token) in
  let+ response = Spotify.Playlist.get_by_id ~client id in
  Lwt.return_ok response.data

let fetch_all_spotify_playlist_tracks ~client id =
  let open Spotify.Spotify_rest_client.Pagination in
  let+ response = Spotify.Playlist.get_tracks_by_id ~client id in
  let fetch_all_tracks ~client tracks pagination =
    let rec aux acc = function
      | None -> Lwt.return_ok acc
      | Some next ->
          let+ { data; pagination } =
            Spotify.Playlist.get_tracks_by_id ~client id
          in
          aux (List.append data acc) pagination.next
    in
    aux tracks pagination.next
  in
  fetch_all_tracks ~client response.data response.pagination

let fetch_all_paginated_spotify_search_results ~client isrc_ids =
  let open Spotify.Spotify_rest_client.Pagination in
  let search_types = [ `Track ] in
  let query = isrc_ids in
  let+ { data = { tracks; _ } } =
    Spotify.Search.search ~client ~search_types ~query ()
  in
  if Option.is_none tracks then Lwt.return_ok []
  else
    let tracks = Option.get tracks in
    let fetch_all_results ~client results (page : 'a Spotify.Page.t option) =
      let rec aux acc = function
        | None -> Lwt.return_ok acc
        | Some next -> (
            let+ { data = { tracks; _ } } =
              Spotify.Search.search ~client ~page:(`Next next) ~query
                ~search_types ()
            in
            match tracks with
            | None -> aux acc None
            | Some tracks when Option.is_some tracks.next ->
                aux (List.append tracks.items acc) (Some tracks)
            | Some tracks -> aux (List.append tracks.items acc) None)
      in
      aux results page
    in
    match tracks.items with
    | [] -> Lwt.return_ok []
    | items -> fetch_all_results ~client items (Some tracks)

let fetch_all_spotify_search_results ~client
    (isrc_ids : (string * [> `Isrc ]) list) =
  let open Infix.Lwt in
  isrc_ids
  |> Lwt_list.map_p (fun query ->
         let* result =
           Spotify.Search.search ~client ~query:[ query ]
             ~search_types:[ `Track ] ()
         in
         match result with
         | Error _ -> Lwt.return @@ Either.right @@ snd query
         | Ok response ->
             if Option.is_some response.data.tracks then
               let tracks = Option.get response.data.tracks in
               tracks.items |> Extended.List.hd_opt
               |> Option.fold
                    ~none:(Either.right @@ snd query)
                    ~some:(fun (track : Spotify.Types.Track.t) ->
                      Either.left track.uri)
               |> Lwt.return
             else Lwt.return @@ Either.right @@ snd query)
  >|= List.partition_map Fun.id

(* let test_get_spotify_playlist_tracks playlist_id =
   let+ client = make_spotify_client () in
   let+ response = fetch_all_spotify_playlist_tracks ~client playlist_id in
   print_endline "Playlist tracks:";
   List.iteri
     (fun idx playlist_track ->
       let open Spotify.Types.Playlist in
       print_endline @@ string_of_int idx ^ ": " ^ playlist_track.track.name)
     response;
   Lwt.return_ok () *)

let test_apple_get_playlist_by_id () =
  Fmt.pr "Here!";
  let+ client = make_apple_client () in
  let+ playlist =
    Apple.Library_playlist.get_by_id ~client
      ~relationships:[ `Tracks; `Catalog ] "p.qQXL6xzSNWBblWo"
  in
  Fmt.pr "Here!!";
  Lwt.return_ok ()

let test_apple_create_playlist () =
  let+ client = make_apple_client () in
  let+ playlist =
    Apple.Library_playlist.create ~client ~name:"Test"
      ~description:"Test description"
      ~tracks:[ { id = "i.kGO5DkBTdX1lWXa"; resource_type = `Library_songs } ]
      ()
  in
  let json = Apple.Library_playlist.Create.output_to_yojson playlist in
  print_endline @@ "Playlist: " ^ Yojson.Safe.pretty_to_string json;
  Lwt.return_ok ()

let test_apple_get_song_by_id () =
  let+ client = make_apple_client () in
  let+ result = Apple.Song.get_by_id ~client "1696596473" in
  Lwt.return_ok ()

let test_apple_get_song_by_isrcs () =
  let+ client = make_apple_client () in
  let+ _result = Apple.Song.get_many_by_isrcs ~client [ "USUM72102276" ] in
  (* print_endline @@ "Song: " ^ Yojson.Safe.pretty_to_string *)
  (* @@ Apple.Song.Get_many_by_isrcs_output.to_yojson result; *)
  Lwt.return_ok ()

let test_transfer_from_spotify_to_apple playlist_id () =
  let+ spotify_client = make_spotify_client () in
  let+ { data = playlist; _ } =
    Spotify.Playlist.get_by_id ~client:spotify_client playlist_id
  in
  let+ spotify_tracks =
    fetch_all_spotify_playlist_tracks ~client:spotify_client playlist_id
  in
  let transfer_tracks, _skipped_tracks =
    List.partition_map
      (fun (playlist_track : Spotify.Types.Playlist.playlist_track) ->
        Transfer.Track.of_spotify playlist_track.track)
      spotify_tracks
  in
  let transfer_playlist =
    Transfer.Playlist.make ~name:playlist.name
      ~description:(Option.value ~default:playlist.name playlist.description)
      ~tracks:transfer_tracks ()
  in
  let+ apple_client = make_apple_client () in
  let+ _ = Transfer.to_apple ~client:apple_client transfer_playlist in
  Lwt.return_ok ()

(* let test_transfer_from_apple_to_spotify ~spotify_user_id playlist_id =
   let+ apple_client = make_apple_client () in
   let+ spotify_client = make_spotify_client () in
   let+ { data; _ } =
     Apple.Library_playlist.get_by_id ~client:apple_client playlist_id
   in
   let| playlist =
     data.data |> Extended.List.hd_opt
     |> Option.to_result
          ~none:
            (Apple.Apple_error.make ~source:(`Source "main") "No songs found")
   in
   Fmt.pr "Apple playlist: %s\n" playlist.attributes.name;
   let+ { data = apple_tracks; _ } =
     Apple.Library_playlist.get_relationship_by_name ~client:apple_client
       ~relationship:`Tracks ~relationships:[ `Catalog ] ~playlist_id ()
   in
   Fmt.pr "Apple tracks: %d\n" @@ List.length apple_tracks;
   let isrc_ids, skipped_library_songs =
     let open Infix.Option in
     List.partition_map
       (fun (library_song : Apple.Types.Library_song.t) ->
         let open Apple.Types.Relationship in
         library_song.relationships
         >>= (fun relationships ->
               relationships.catalog >>= function
               | `Catalog_song song ->
                   Extended.List.hd_opt song.data >>= fun catalog_song ->
                   catalog_song.attributes.isrc
               | _ -> None)
         |> Option.fold ~none:(Either.right library_song) ~some:Either.left)
       apple_tracks
   in
   Fmt.pr "ISRCs: %d\n" @@ List.length isrc_ids;
   Fmt.pr "Skipped library songs: %d\n" @@ List.length skipped_library_songs;
   let* spotify_uris, skipped_isrcs =
     isrc_ids
     |> List.map (fun id -> (id, `Isrc))
     |> fetch_all_spotify_search_results ~client:spotify_client
   in
   Fmt.pr "Spotify URIs: %d\n" @@ List.length spotify_uris;
   Fmt.pr "Skipped ISRCs: %d\n" @@ List.length skipped_isrcs;
   let+ spotify_playlist =
     Spotify.Playlist.create ~client:spotify_client
       ~description:
         (playlist.attributes.description
         |> Option.map (fun (description : Apple.Types.Description.t) ->
                description.standard)
         |> Option.value ~default:playlist.attributes.name)
       ~name:playlist.attributes.name ~user_id:spotify_user_id ()
   in
   let+ _ =
     Spotify.Playlist.add_tracks ~client:spotify_client ~track_uris:spotify_uris
       spotify_playlist.data.id
   in
   Lwt.return_ok () *)

let () =
  let res =
    Lwt_main.run
    @@ test_transfer_from_spotify_to_apple "37i9dQZF1DWXJyjYpHunCf" ()
  in
  match res with
  | Ok _ -> print_endline "Success"
  | Error err ->
      Error.cause err |> Option.get |> fun err ->
      print_endline @@ Error.to_string err
