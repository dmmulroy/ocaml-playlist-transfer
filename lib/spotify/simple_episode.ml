type t = {
  audio_preview_url : Http.Uri.t;
  description : string;
  html_description : string;
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  is_externally_hosted : bool;
  is_playable : bool;
  languages : string list;
  name : string;
  release_date : string;
  release_date_precision : string;
}
