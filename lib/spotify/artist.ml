type resource_type = [ `Artist ]

let resource_type_of_yojson = function
  | `String "artist" -> Ok `Artist
  | _ -> Error "resource_type"

let resource_type_to_yojson = function `Artist -> `String "artist"

(* TODO: Investigate using "simplified" object types (https://github.com/spotify-api/spotify-types/blob/master/typings/artist.d.ts#L9)*)
type t = {
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; [@default None] (* nullable *)
  genres : string list option; [@default None] (* nullable *)
  href : Http.Uri.t;
  id : string;
  images : Common.image list option; [@default None] (* nullable *)
  name : string;
  popularity : int option; [@default None] (* nullable *)
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]
