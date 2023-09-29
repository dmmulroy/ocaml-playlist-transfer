(* open Shared *)

type t = {
  id :
    [ `Apple_library_id of string
    | `Apple_catalog_id of string
    | `Spotify_uri of string ];
  isrc : string;
  name : string;
}
[@@deriving make]

type apple_track =
  [ `Library_song of Apple.Library_song.t
  | `Library_music_video of Apple.Library_music_video.t ]

(* let of_apple (track : apple_track) =
   match track with `Library_music_video video -> Either.right video
   | `Library_song song -> *)

let of_spotify (track : Spotify.Track.t) =
  match track.external_ids.isrc with
  | None -> Either.right @@ track
  | Some isrc ->
      Either.left @@ make ~id:(`Spotify_uri track.uri) ~isrc ~name:track.name
