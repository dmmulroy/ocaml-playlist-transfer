type t = {
  external_urls : External_urls.t;
  href : Http.Uri.t;
  id : string;
  name : string;
  resource_type : string;
  uri : string;
}
[@@deriving yojson]
