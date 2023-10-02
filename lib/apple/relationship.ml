type request = [ `Catalog | `Tracks ]

let request_to_string = function
  | `Catalog -> "catalog"
  | `Tracks -> "tracks"
  | #request -> .

let request_of_string = function
  | "catalog" -> Ok `Catalog
  | "tracks" -> Ok `Tracks
  | _ -> Error "Invalid relationship"

let request_of_yojson = function
  | `String relationship -> request_of_string relationship
  | _ -> Error "Invalid relationship"

let request_to_yojson relationship = `String (request_to_string relationship)

let request_of_string_list relationship =
  List.filter_map
    (fun resource -> Result.to_option @@ request_of_string resource)
    relationship

let request_to_string_list relationships =
  List.map request_to_string relationships
