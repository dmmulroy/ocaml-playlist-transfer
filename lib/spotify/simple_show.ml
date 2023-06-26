type t = {
  available_markets : string list;
  copyrights : Common.copyright list;
  description : string;
  html_description : string;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  is_externally_hosted : bool;
  languages : string list;
  media_type : string;
  name : string;
  publisher : string;
  resource_type : Resource.t; [@key "type"]
  uri : string;
  total_episodes : int;
}
[@@deriving yojson]
