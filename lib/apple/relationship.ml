type t = ([ `Catalog | `Tracks ][@deriving yojson])

let to_string = function `Catalog -> "catalog" | `Tracks -> "tracks" | #t -> .

let of_string = function
  | "catalog" -> Ok `Catalog
  | "tracks" -> Ok `Tracks
  | _ -> Error "Invalid relationship"

let of_yojson = function
  | `String "catalog" -> Ok `Catalog
  | `String "tracks" -> Ok `Tracks
  | _ -> Error "Invalid resource type"

let to_yojson = function
  | `Catalog -> `String "catalog"
  | `Tracks -> `String "tracks"
  | #t -> .

let of_string_list resources =
  List.filter_map
    (fun resource -> Result.to_option @@ of_string resource)
    resources

let to_string_list resources = List.map to_string resources
