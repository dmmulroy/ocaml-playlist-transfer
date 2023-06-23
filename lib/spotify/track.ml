type resource_type = [ `Track ]

let resource_type_of_yojson = function
  | `String "track" -> Ok `Track
  | _ -> Error "Invalid track resource_type"

let resource_type_to_yojson = function `Track -> `String "track"

type linked_track = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  resource_type : resource_type; [@key "type"]
  uri : string;
}
[@@deriving yojson]

type simple = {
  artists : Artist.Simple.t list;
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option;
  linked_from : linked_track option;
  name : string;
  preview_url : string option;
  resource_type : resource_type; [@key "type"]
  restrictions : Common.restriction list option;
  track_number : int;
  uri : Uri.t;
}
[@@deriving yojson]

type t = {
  album : Album.simple;
  artists : Artist.Simple.t list;
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_ids : Common.external_ids;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option; [@default None]
  linked_from : linked_track option; [@default None]
  name : string;
  popularity : int;
  preview_url : string option;
  resource_type : resource_type; [@key "type"]
  restrictions : Common.restriction list option; [@default None]
  track_number : int;
  uri : Uri.t;
}
[@@deriving yojson { strict = false }]
