open Shared

type album_type = [ `Album | `Single | `Compilation ]
type album_group = [ album_type | `Appears_on ]

let album_type_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "single" -> Ok `Single
  | `String "compilation" -> Ok `Compilation
  | _ -> Error "Invalid album album_type"

let album_type_to_yojson = function
  | `Album -> `String "album"
  | `Single -> `String "single"
  | `Compilation -> `String "compilation"
  | #album_type -> .

let album_group_of_yojson = function
  | `String "appears_on" -> Ok `Appears_on
  | json -> album_type_of_yojson json

let album_group_to_yojson = function
  | `Appears_on -> `String "appears_on"
  | #album_type as group -> album_type_to_yojson group
  | #album_group -> .

type t = {
  album_group : album_group option; [@default None]
  album_type : album_type;
  artists : Artist.t list;
  available_markets : string list;
  copyrights : Common.copyright list;
  external_urls : Common.external_urls;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  label : string;
  name : string;
  popularity : int;
  release_date : string;
  release_date_precision : Common.release_date_precision;
  resource_type : Resource.t; [@key "type"]
  restrictions : Common.restriction list option; [@default None]
  total_tracks : int;
  tracks : Simple_track.t list;
  uri : string;
}
[@@deriving yojson]
