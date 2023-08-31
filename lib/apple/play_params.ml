type kind = ([ `Playlist | `Song ][@deriving yojson])

let kind_to_string = function `Playlist -> "playlist" | `Song -> "song"

let kind_of_string = function
  | "playlist" -> Ok `Playlist
  | "song" -> Ok `Song
  | _ -> Error "Invalid kind"

let kind_to_yojson kind = `String (kind_to_string kind)

let kind_of_yojson = function
  | `String s -> kind_of_string s
  | _ -> Error "Invalid kind"

type t = {
  catalog_id : string option; [@default None] [@key "catalogId"]
  global_id : string option; [@default None] [@key "globalId"]
  id : string;
  is_library : bool; [@key "isLibrary"]
  kind : kind;
  reporting : bool option; [@default None]
  reporting_id : string option; [@default None] [@key "reportingId"]
  version_hash : string option; [@default None] [@key "versionHash"]
}
[@@deriving yojson]
