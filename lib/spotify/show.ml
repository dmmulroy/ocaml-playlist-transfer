open Shared

type t = {
  available_markets : string list;
  copyrights : Common.copyright list;
  description : string;
  episodes : Simple_episode.t list;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  html_description : string;
  id : string;
  images : Common.image list;
  is_externally_hosted : bool;
  languages : string list;
  media_type : string;
  name : string;
  publisher : string;
  resource_type : Resource.t; [@key "type"]
  total_episodes : int;
  uri : string;
}
[@@deriving yojson]
