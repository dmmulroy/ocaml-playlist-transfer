type album_type = [ `Album | `Single | `Compilation ]
type album_group = [ album_type | `Appears_on ]
type release_date_precision = [ `Year | `Month | `Day ]
type resource_type = [ `Album ]
type restrictions_reason = [ `Market | `Product | `Explicit ]

let restrictions_reason_of_yojson = function
  | `String "market" -> Ok `Market
  | `String "product" -> Ok `Product
  | `String "explicit" -> Ok `Explicit
  | _ -> Error "restrictions_reason"

let restrictions_reason_to_yojson = function
  | `Market -> `String "market"
  | `Product -> `String "product"
  | `Explicit -> `String "explicit"

type restrictions = { reason : restrictions_reason } [@@deriving yojson]

let album_type_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "single" -> Ok `Single
  | `String "compilation" -> Ok `Compilation
  | _ -> Error "album_type"

let album_type_to_yojson = function
  | `Album -> `String "album"
  | `Single -> `String "single"
  | `Compilation -> `String "compilation"

let album_group_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "single" -> Ok `Single
  | `String "compilation" -> Ok `Compilation
  | `String "appears_on" -> Ok `Appears_on
  | _ -> Error "album_group"

let album_group_to_yojson = function
  | `Album -> `String "album"
  | `Single -> `String "single"
  | `Compilation -> `String "compilation"
  | `Appears_on -> `String "appears_on"

let release_date_precision_of_yojson = function
  | `String "year" -> Ok `Year
  | `String "month" -> Ok `Month
  | `String "day" -> Ok `Day
  | _ -> Error "release_date_precision"

let release_date_precision_to_yojson = function
  | `Year -> `String "year"
  | `Month -> `String "month"
  | `Day -> `String "day"

let resource_type_of_yojson = function
  | `String "album" -> Ok `Album
  | _ -> Error "album resource_type"

let resource_type_to_yojson = function `Album -> `String "album"

type simple = {
  album_group : album_group option;
  album_type : album_type;
  artists : Artist.simple list;
  available_markets : string list;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  release_date : string;
  release_date_precision : release_date_precision;
  restrictions : restrictions list option;
  total_tracks : int;
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

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
  resource_type : resource_type; [@key "type"]
  restrictions : restrictions list option; [@default None]
  total_tracks : int;
  (* tracks : Track.t list; (* TODO: Make Track.simple *) *)
  uri : Uri.t;
}
[@@deriving yojson]
