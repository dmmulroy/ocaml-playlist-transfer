type album_type = [ `Album | `Single | `Compilation ]
type album_group = [ album_type | `Appears_on ]
type release_date_precision = [ `Year | `Month | `Day ]

let album_type_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "single" -> Ok `Single
  | `String "compilation" -> Ok `Compilation
  | _ -> Error "Invalid album album_type"

let album_type_to_yojson = function
  | `Album -> `String "album"
  | `Single -> `String "single"
  | `Compilation -> `String "compilation"

let album_group_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "single" -> Ok `Single
  | `String "compilation" -> Ok `Compilation
  | `String "appears_on" -> Ok `Appears_on
  | _ -> Error "Invalid album album_group"

let album_group_to_yojson = function
  | `Album -> `String "album"
  | `Single -> `String "single"
  | `Compilation -> `String "compilation"
  | `Appears_on -> `String "appears_on"

let release_date_precision_of_yojson = function
  | `String "year" -> Ok `Year
  | `String "month" -> Ok `Month
  | `String "day" -> Ok `Day
  | _ -> Error "Invalid album release_date_precision"

let release_date_precision_to_yojson = function
  | `Year -> `String "year"
  | `Month -> `String "month"
  | `Day -> `String "day"

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
  release_date_precision : release_date_precision;
  resource_type : Resource.t; [@key "type"]
  restrictions : Common.restriction list option; [@default None]
  total_tracks : int;
  (* tracks : Track.Simple.t list; *)
  uri : string;
}
[@@deriving yojson]
