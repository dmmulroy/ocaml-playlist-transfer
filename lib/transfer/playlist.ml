open Syntax
open Let

(*
 * let playlist, failed_tracks = Transfer.Playlist.of_apple apple_playlist in
 * let spotify_playlist, failed_tracks' = Transfer.Playlist.to_spotify playlist in
 *)
type t = { description : string; name : string; tracks : Track.t list option }

let either_of_apple_track = function
  | `Library_music_video video ->
      Either.right @@ Track.of_apple_library_music_video video
  | `Library_song (song : Apple.Library_song.t) -> (
      let catalog_id =
        Infix.Option.(
          song.attributes.play_params >>= fun play_params ->
          play_params.catalog_id)
      in
      match catalog_id with
      | None -> Either.right @@ Track.of_apple (`Library_song song)
      | Some catalog_id -> Either.left catalog_id)

(* (Playlist.t * Track.t list) where Track.t list is a list of songs that we failed to convert*)
(* val of_apple : Apple.Client.t -> Apple.Library_playlist.t -> (Playlist.t * Track.t list) Lwt.t *)
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
            Some (Track.of_apple_library_music_video video)
        | `Library_song (song : Apple.Library_song.t) -> (
            let catalog_id_opt =
              Infix.Option.(
                song.attributes.play_params >>= fun play_params ->
                play_params.catalog_id)
            in
            match catalog_id_opt with
            | None -> Some (Track.of_apple (`Library_song song))
            | Some catalog_id ->
                Hashtbl.add song_by_catalog_id catalog_id track;
                None))
      tracks
  in
  let library_songs = List.of_seq @@ Hashtbl.to_seq song_by_catalog_id in
  let track_promises =
    List.map
      (fun (catalog_id, song) ->
        let get_by_id_input = Apple.Song.Get_by_id_input.make catalog_id in
        let* response = Apple.Song.get_by_id ~client get_by_id_input in
        match response with
        | Error _ -> Lwt.return @@ Either.right @@ Track.of_apple song
        | Ok { data } ->
            let song =
              try Track.of_apple (`Catalog_song (List.hd data))
              with _ -> Track.of_apple song
            in
            Lwt.return
            @@
            if Option.is_some song.isrc then Either.left song
            else Either.right song)
      library_songs
  in
  let* eithers = Lwt.all track_promises in
  let tracks, skipped_tracks' = List.partition_map Fun.id eithers in
  Lwt.return_ok
    ( { description; name; tracks = Some tracks },
      skipped_tracks' @ skipped_tracks )

let of_spotify (_client : Spotify.Client.t) (playlist : Spotify.Playlist.t) =
  let name = playlist.name in
  let description = Option.value ~default:playlist.name playlist.description in
  let tracks, skipped_tracks =
    List.partition_map
      (fun (item : Spotify.Playlist.playlist_track) ->
        match item.track.external_ids.isrc with
        | None -> Either.right @@ Track.of_spotify item.track
        | Some _ -> Either.left @@ Track.of_spotify item.track)
      playlist.tracks.items
  in
  ({ description; name; tracks = Some tracks }, skipped_tracks)

(* type track = { *)
(*   id : string; *)
(*   resource_type : *)
(*     [ `Library_songs | `Library_music_videos | `Music_videos | `Songs ]; *)
(*       [@key "type"] [@to_yojson Resource.to_yojson] *)
(* } *)

let to_apple (playlist : t) =
  (* TODO: If a Track.id is of `Spotify_id search spotify via isrc id *)
  (* let _tracks = *)
  (*   Infix.Option.( *)
  (*     playlist.tracks *)
  (*     >|= List.map (fun track -> *)
  (*             match track with *)
  (*             | `Apple_library_id id -> { id; resource_type = `Library_songs } *)
  (* (*             | `Apple_catalog_id id -> { id; resource_type = `Songs })) *) *)
  (* in *)
  Apple.Library_playlist.Create_input.make ~description:playlist.description
    ~name:playlist.name ~tracks:[] ()
