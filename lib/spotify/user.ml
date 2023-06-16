type t = {
  external_urls : Common.external_urls;
  followers : Resource_type.reference option; (* nullable *) [@default None]
  href : string;
  id : string;
  resource_type : [ `User ];
      [@key "type"]
      [@of_yojson Resource_type.user_of_yojson]
      [@to_yojson Resource_type.user_to_yojson]
  uri : string;
  display_name : string option; [@default None] (* nullable *)
}
[@@deriving yojson]
