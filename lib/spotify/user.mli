type t = {
  external_urls : Common.external_urls;
  followers : Resource_type.reference option;
  href : Http.Uri.t;
  id : string;
  resource_type : [ `User ];
  uri : Uri.t;
  display_name : string option;
}
[@@deriving yojson]
