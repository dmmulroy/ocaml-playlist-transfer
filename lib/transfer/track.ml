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
