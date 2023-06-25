type t = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  name : string;
  resource_type : Resource.t; [@key "type"]
  uri : string;
}
[@@deriving yojson]
