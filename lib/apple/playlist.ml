open Shared

type playlist_type =
  [ `Editoral | `External | `Personal_mix | `Replay | `User_shared ]
[@@deriving yojson]

let playlist_type_to_string = function
  | `Editoral -> "editorial"
  | `External -> "external"
  | `Personal_mix -> "personal-mix"
  | `Replay -> "replay"
  | `User_shared -> "user-shared"
  | #playlist_type -> .

let playlist_type_of_string = function
  | "editorial" -> Ok `Editoral
  | "external" -> Ok `External
  | "personal-mix" -> Ok `Personal_mix
  | "replay" -> Ok `Replay
  | "user-shared" -> Ok `User_shared
  | _ -> Error "Invalid playlist type"

let playlist_type_to_yojson playlist_type =
  `String (playlist_type_to_string playlist_type)

let playlist_type_of_yojson = function
  | `String playlist_type -> playlist_type_of_string playlist_type
  | _ -> Error "Invalid playlist type"

type attributes = {
  artwork : Artwork.t option; [@default None]
  curator_name : string; [@key "curatorName"]
  is_chart : bool; [@key "isChart"]
  description : Description.t option; [@default None]
  last_modified_date : string option; [@key "lastModifiedDate"] [@default None]
  name : string;
  playlist_type : playlist_type; [@key "playlistType"]
  play_params : Play_params.t option; [@key "playParams"] [@default None]
  track_types : Resource.t list option; [@key "trackTypes"] [@default None]
  url : Http.Uri.t;
}
[@@deriving yojson]

(* TODO: relationships & views *)
type t = {
  id : string;
  href : string;
  resource_type : Resource.t; [@key "type"]
  attributes : attributes;
      (* realationships : unit option; [@default None] *)
      (* views : unit option; [@default None] *)
}
[@@deriving yojson { strict = false }]
