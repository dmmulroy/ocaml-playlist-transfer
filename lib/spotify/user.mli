type t = {
  display_name : string option;
  external_urls : Common.external_urls;
  followers : Resource_type.reference option;
  href : Http.Uri.t;
  id : string;
  image : Common.image list option;
  resource_type : [ `User ];
  uri : Uri.t;
}
[@@deriving yojson]

module Me : sig
  type product = [ `Premium | `Free | `Open ]

  type explicit_content = { filter_enabled : bool; filter_locked : bool }
  [@@deriving yojson]

  type t = {
    country : string;
    email : string;
    explicit_content : explicit_content option;
    product : product;
    display_name : string option;
    external_urls : Common.external_urls;
    followers : Resource_type.reference option;
    href : Http.Uri.t;
    id : string;
    image : Common.image list option;
    resource_type : [ `User ];
    uri : Uri.t;
  }
  [@@deriving yojson]
end

