type t = [ `Catalog | `Tracks ]

let to_string = function `Catalog -> "catalog" | `Tracks -> "tracks" | #t -> .

let of_string = function
  | "catalog" -> Ok `Catalog
  | "tracks" -> Ok `Tracks
  | _ -> Error (`Msg "Invalid relationship")

let of_yojson = function
  | `String relationship -> of_string relationship
  | _ -> Error (`Msg "Invalid relationship type")

let to_yojson relationship = `String (to_string relationship)

let of_string_list relationship =
  List.filter_map
    (fun resource -> Result.to_option @@ of_string resource)
    relationship

let to_string_list relationship = List.map to_string relationship

type 'a response = {
  href : string option; [@default None]
  data : 'a list;
  next : Page.next option; [@default None]
}
[@@deriving yojson]
