type t = {
  external_urls : Common.external_urls;
  followers : Resource.reference option; (* nullable *) [@default None]
  href : string;
  id : string;
  resource_type : [ `User ];
      [@key "type"]
      [@of_yojson Resource.user_resource_of_yojson]
      [@to_yojson Resource.user_resource_to_yojson]
  uri : string;
  display_name : string option; (* nullable *)
}
[@@deriving yojson]
