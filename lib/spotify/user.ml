open Shared

type t = {
  display_name : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource.reference option; [@default None]
  href : Http.Uri.t;
  id : string;
  image : Common.image list option; [@default None]
  resource_type : Resource.t; [@key "type"]
  uri : string;
}
[@@deriving yojson]
