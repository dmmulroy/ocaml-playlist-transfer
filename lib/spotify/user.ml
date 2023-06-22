(* TODO Thursday: Resource_type module and remove { strict = false } where possible *)
type resource_type = [ `User ]

let resource_type_of_yojson = function
  | `String "user" -> Ok `User
  | _ -> Error "Invalid user resource_type"

let resource_type_to_yojson = function `User -> `String "user"

type t = {
  display_name : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Common.reference option; [@default None]
  href : Http.Uri.t;
  id : string;
  image : Common.image list option; [@default None]
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]

module Me = struct
  type product = [ `Premium | `Free | `Open ]

  type explicit_content = { filter_enabled : bool; filter_locked : bool }
  [@@deriving yojson]

  let product_of_yojson = function
    | `String "premium" -> Ok `Premium
    | `String "free" -> Ok `Free
    | `String "open" -> Ok `Open
    | _ -> Error "Invalid product"

  let product_to_yojson = function
    | `Premium -> `String "premium"
    | `Free -> `String "free"
    | `Open -> `String "open"

  type t = {
    country : string;
    email : string;
    explicit_content : explicit_content option; [@default None]
    product : product;
    display_name : string option; [@default None]
    external_urls : Common.external_urls;
    followers : Common.reference option; [@default None]
    href : Http.Uri.t;
    id : string;
    image : Common.image list option; [@default None]
    resource_type : resource_type; [@key "type"]
    uri : Uri.t;
  }
  [@@deriving yojson]
end
