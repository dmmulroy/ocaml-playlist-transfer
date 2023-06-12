type t = {
  external_urls : Common.external_urls;
  followers : Resource.reference option; (* nullable *)
  href : string;
  id : string;
  resource_type : [ `User ];
  uri : string;
  display_name : string option; (* nullable *)
}
[@@deriving yojson]
