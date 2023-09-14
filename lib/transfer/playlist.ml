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
      | None -> Either.right @@ Track.of_apple (`Library song)
      | Some catalog_id -> Either.left catalog_id)

(* (Playlist.t * Track.t list) where Track.t list is a list of songs that we failed to convert*)
(* val of_apple : Apple.Client.t -> Apple.Library_playlist.t -> (Playlist.t * Track.t list) Lwt_result.t *)
let of_apple (client : Apple.Client.t) (playlist : Apple.Library_playlist.t) =
  let name = playlist.attributes.name in
  let description =
    Option.fold ~none:playlist.attributes.name
      ~some:(fun (description : Apple.Description.t) -> description.standard)
      playlist.attributes.description
  in
  let catalog_ids, _skipped_tracks =
    match Apple.Library_playlist.tracks playlist with
    | None -> ([], [])
    | Some tracks ->
        List.fold_left
          (fun (catalog_ids, skipped_tracks) track ->
            match track with
            | `Library_music_video video ->
                ( catalog_ids,
                  Track.of_apple_library_music_video video :: skipped_tracks )
            | `Library_song (song : Apple.Library_song.t) -> (
                let catalog_id =
                  Infix.Option.(
                    song.attributes.play_params >>= fun play_params ->
                    play_params.catalog_id)
                in
                match catalog_id with
                | None ->
                    ( catalog_ids,
                      Track.of_apple (`Library song) :: skipped_tracks )
                | Some catalog_id -> (catalog_id :: catalog_ids, skipped_tracks)
                ))
          ([], []) tracks
  in
  let track_promises =
    List.map
      (fun catalog_id ->
        let get_by_id_input = Apple.Song.Get_by_id_input.make catalog_id in
        let+ response = Apple.Song.get_by_id ~client get_by_id_input in
        let song = List.hd response.data in
        Lwt.return_ok @@ Track.of_apple (`Catalog song))
      catalog_ids
  in
  let _ = Lwt_list.map_p (fun promise -> promise) track_promises in
  { description; name; tracks = None }

let of_spotify (playlist : Spotify.Playlist.t) =
  let name = playlist.name in
  let description = Option.value ~default:playlist.name playlist.description in
  let tracks =
    Option.some
    @@ List.map
         (fun (playlist_track : Spotify.Playlist.playlist_track) ->
           Track.of_spotify playlist_track.track)
         playlist.tracks.items
  in
  { description; name; tracks }
