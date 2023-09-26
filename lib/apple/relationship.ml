type t = [ `Catalog | `Tracks ]

let to_string = function `Catalog -> "catalog" | `Tracks -> "tracks" | #t -> .

let of_string = function
  | "catalog" -> Ok `Catalog
  | "tracks" -> Ok `Tracks
  | _ -> Error "Invalid relationship"

let of_yojson = function
  | `String relationship -> of_string relationship
  | _ -> Error "Invalid relationship"

let to_yojson relationship = `String (to_string relationship)

let of_string_list relationship =
  List.filter_map
    (fun resource -> Result.to_option @@ of_string resource)
    relationship

let to_string_list relationships = List.map to_string relationships
