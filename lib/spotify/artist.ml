type resource_type = [ `Artist ]

let resource_type_of_yojson = function
  | `String "artist" -> Ok `Artist
  | _ -> Error "Invalid artist resource_type"

let resource_type_to_yojson = function `Artist -> `String "artist"

type simple = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  name : string;
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

type t = {
  external_urls : Common.external_urls;
  followers : Resource_type.reference;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  popularity : int;
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]
