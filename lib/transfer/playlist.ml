open Shared
open Syntax
open Let

type t = { description : string; name : string; tracks : Track.t list option }
[@@deriving make]

let add_track playlist track =
  let existing_tracks = Option.value ~default:[] playlist.tracks in
  let updated_tracks = track :: existing_tracks in
  { playlist with tracks = Some updated_tracks }

let add_tracks playlist tracks =
  let existing_tracks = Option.value ~default:[] playlist.tracks in
  let updated_tracks = List.append existing_tracks tracks in
  { playlist with tracks = Some updated_tracks }

let of_apple ~(client : Apple.Client.t)
    (playlist : Apple.Types.Library_playlist.t) =
  let name = playlist.attributes.name in
  let description =
    Option.fold ~none:playlist.attributes.name
      ~some:(fun (description : Apple.Types.Description.t) ->
        description.standard)
      playlist.attributes.description
  in
  let tracks =
    Option.value ~default:[] @@ Apple.Types.Library_playlist.tracks playlist
  in
  let song_by_catalog_id = Hashtbl.create @@ List.length tracks in
  let skipped_tracks =
    List.filter_map
      (fun track ->
        match track with
        | `Library_music_video (video : Apple.Types.Library_music_video.t) ->
            Some (`Library_music_video video)
        | `Library_song (song : Apple.Types.Library_song.t) -> (
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
              let catalog_song = List.hd data.data in
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
  let _ = List.partition_map Fun.id eithers in
  let tracks, skipped_tracks' = List.partition_map Fun.id eithers in
  Lwt.return_ok
    ( { description; name; tracks = Some tracks },
      skipped_tracks' @ skipped_tracks )

let of_spotify ~client:(_client : Spotify.Client.t)
    (playlist : Spotify.Types.Playlist.t) =
  let open Spotify.Types.Playlist in
  let name = playlist.name in
  let description = Option.value ~default:name playlist.description in
  let tracks, skipped_tracks =
    List.partition_map
      (fun item -> Track.of_spotify item.track)
      playlist.tracks.items
  in
  Lwt.return_ok ({ description; name; tracks = Some tracks }, skipped_tracks)
