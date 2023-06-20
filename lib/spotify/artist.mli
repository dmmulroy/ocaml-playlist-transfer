type t = {
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; (* nullable *)
  genres : string list option; (* nullable *)
  href : Http.Uri.t;
  id : string;
  images : Common.image list option; (* nullable *)
  name : string;
  popularity : int option; (* nullable *)
  resource_type : [ `Artist ];
  uri : Uri.t;
}
[@@deriving yojson]

