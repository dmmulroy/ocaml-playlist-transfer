open Syntax
open Let

(*
 * let playlist, failed_tracks = Transfer.Playlist.of_apple ~client apple_playlist in
 * let spotify_playlist, failed_tracks' = Transfer.Playlist.to_spotify ~client playlist in
 *)
type t = { description : string; name : string; tracks : Track.t list option }
[@@deriving make]

let of_apple (client : Apple.Client.t) (playlist : Apple.Library_playlist.t) =
  let name = playlist.attributes.name in
  let description =
    Option.fold ~none:playlist.attributes.name
      ~some:(fun (description : Apple.Description.t) -> description.standard)
      playlist.attributes.description
  in
  let tracks =
    Option.value ~default:[] @@ Apple.Library_playlist.tracks playlist
  in
  let song_by_catalog_id = Hashtbl.create @@ List.length tracks in
  let skipped_tracks =
    List.filter_map
      (fun track ->
        match track with
        | `Library_music_video (video : Apple.Library_music_video.t) ->
            Some (`Library_music_video video)
        | `Library_song (song : Apple.Library_song.t) -> (
            let catalog_id_opt =
              Infix.Option.(
                song.attributes.play_params >>= fun play_params ->
                play_params.catalog_id)
            in
            match catalog_id_opt with
            | None -> Some (`Library_song song)
            | Some catalog_id ->
                Hashtbl.add song_by_catalog_id catalog_id track;
                None))
      tracks
  in
  let library_songs = List.of_seq @@ Hashtbl.to_seq song_by_catalog_id in
  let track_promises =
    List.map
      (fun (catalog_id, song) ->
        let* response = Apple.Song.get_by_id ~client catalog_id in
        match response with
        | Error _ -> Lwt.return @@ Either.right @@ song
        | Ok { data } -> (
            try
              let catalog_song = List.hd data in
              match catalog_song.attributes.isrc with
              | None -> Lwt.return @@ Either.right song
              | Some isrc ->
                  Lwt.return @@ Either.left
                  @@ Track.make ~id:(`Apple_catalog_id catalog_id) ~isrc
                       ~name:catalog_song.attributes.name
            with _ -> Lwt.return @@ Either.right song))
      library_songs
  in
  let* eithers = Lwt.all track_promises in
  let tracks, skipped_tracks' = List.partition_map Fun.id eithers in
  Lwt.return_ok
    ( { description; name; tracks = Some tracks },
      skipped_tracks' @ skipped_tracks )

let of_spotify (_client : Spotify.Client.t) (playlist : Spotify.Playlist.t) =
  let name = playlist.name in
  let description = Option.value ~default:name playlist.description in
  let tracks, skipped_tracks =
    List.partition_map
      (fun (item : Spotify.Playlist.playlist_track) ->
        match item.track.external_ids.isrc with
        | None -> Either.right @@ item.track
        | Some isrc ->
            Either.left
            @@ Track.make ~id:(`Spotify_uri item.track.uri) ~isrc
                 ~name:item.track.name)
      playlist.tracks.items
  in
  print_endline @@ "of_spotify tracks: " ^ string_of_int (List.length tracks);
  print_endline @@ "of_spotify skipped_tracks: "
  ^ string_of_int (List.length skipped_tracks);
  Lwt.return_ok ({ description; name; tracks = Some tracks }, skipped_tracks)

let to_apple (client : Apple.Client.t) (playlist : t) =
  print_endline @@ "playlist track count: "
  ^ string_of_int (Option.value ~default:[] playlist.tracks |> List.length);
  let isrcs =
    Infix.Option.(
      playlist.tracks >|= List.map (fun (track : Track.t) -> track.isrc))
    |> Option.value ~default:[]
  in
  let+ { meta; _ } = Apple.Song.get_many_by_isrcs ~client isrcs in
  let tracks =
    let open Apple.Library_playlist.Create_input in
    let open Apple.Song.Get_many_by_isrcs_output in
    List.fold_left
      (fun acc (isrc, list) ->
        List.fold_left
          (fun acc' track ->
            match List.mem_assq isrc acc' with
            | true -> acc'
            | false -> (isrc, track.id) :: acc')
          acc list)
      [] meta.filters.isrc
    |> List.map (fun (_, catalog_id) : track ->
           { id = catalog_id; resource_type = `Songs })
  in
  print_endline @@ "tracks: " ^ string_of_int (List.length tracks);
  let create_input =
    Apple.Library_playlist.Create_input.make ~name:playlist.name
      ~description:playlist.description ~tracks ()
  in
  Apple.Library_playlist.create ~client create_input

(* let to_spotify ?options (client : Spotify.Client.t) (playlist : Playlist.t) = *)
(*   let isrcs = *)
(*     Infix.Option.( *)
(*       playlist.tracks >|= List.map (fun (track : Track.t) -> track.isrc)) *)
(*     |> Option.value ~default:[] *)
(*   in *)
(*   () *)
