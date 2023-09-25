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

let of_spotify (track : Spotify.Track.t) =
  match track.external_ids.isrc with
  | None -> Either.right @@ track
  | Some isrc ->
      Either.left @@ make ~id:(`Spotify_uri track.uri) ~isrc ~name:track.name
