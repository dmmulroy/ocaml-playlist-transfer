type t = {
  external_urls : External_urls.t;
  href : Http.Uri.t;
  id : string;
  resource_type : string; [@key "type"]
  uri : string;
}
[@@deriving yojson]
