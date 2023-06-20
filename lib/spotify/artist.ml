(* type album_type = [ `Album | `Single | `Compilation ] *)
(* type release_date = [ `Year | `Month | `Day ] *)
type resource_type = [ `Artist ]

let resource_type_of_yojson = function
  | `String "artist" -> Ok `Artist
  | _ -> Error "resource_type"

let resource_type_to_yojson = function `Artist -> `String "artist"

(* type restrictions_reason = [ `Market | `Product | `Explicit ] *)
(* [@@deriving yojson] *)

(* type restrictions = { reason : restrictions_reason } [@@deriving yojson] *)
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

(* let album_type_of_yojson = function *)
(*   | `String "album" -> Ok `Album *)
(*   | `String "single" -> Ok `Single *)
(*   | `String "compilation" -> Ok `Compilation *)
(*   | _ -> Error "album_type" *)

(* let album_type_to_yojson = function *)
(*   | `Album -> `String "album" *)
(*   | `Single -> `String "single" *)
(*   | `Compilation -> `String "compilation" *)

(* let release_date_of_yojson = function *)
(*   | `String "year" -> Ok `Year *)
(*   | `String "month" -> Ok `Month *)
(*   | `String "day" -> Ok `Day *)
(*   | _ -> Error "release_date" *)

(* let release_date_to_yojson = function *)
(*   | `Year -> `String "year" *)
(*   | `Month -> `String "month" *)
(*   | `Day -> `String "day" *)
