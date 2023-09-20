open Shared

type t = {
  audio_preview_url : Http.Uri.t;
  description : string;
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  html_description : string;
  id : string;
  images : Common.image list;
  is_externally_hosted : bool;
  is_playable : bool;
  languages : string list;
  name : string;
  release_date : string;
  release_date_precision : string;
  resource_type : Resource.t; [@key "type"]
  restrictions : Common.restriction option; [@default None]
  resume_point : Episode.resume_point;
  uri : string;
}
[@@deriving yojson]
