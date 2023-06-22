(* TODO Thursday: Refactor this module, Resource_type module, and remove { strict = false } where possible *)
type resource_type = [ `User ]

let resource_type_of_yojson = function
  | `String "user" -> Ok `User
  | _ -> Error "Invalid user resource_type"

let resource_type_to_yojson = function `User -> `String "user"

type t = {
  display_name : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; [@default None]
  href : Http.Uri.t;
  id : string;
  image : Common.image list option; [@default None]
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

type pub = {
  display_name : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; [@default None]
  href : Http.Uri.t;
  id : string;
  image : Common.image list option; [@default None]
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

type priv = {
  display_name : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; [@default None]
  href : Http.Uri.t;
  id : string;
  image : Common.image list option; [@default None]
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

type t2 = [ `Public of pub | `Private of priv ]
