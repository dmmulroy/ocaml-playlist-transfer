type t = {
  audio_preview_url : Http.Uri.t option; [@default None]
  description : string option; [@default None]
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  html_description : string option; [@default None]
  id : string;
  images : Common.image list option; [@default None]
  is_externally_hosted : bool option; [@default None]
  is_playable : bool;
  languages : string list option; [@default None]
  name : string;
  release_date : string option; [@default None]
  release_date_precision : string option; [@default None]
  resource_type : Resource.t; [@key "type"]
  restrictions : Common.restriction option; [@default None]
  resume_point : resume_point option; [@default None]
  uri : string;
}
[@@deriving yojson]

and resume_point = { fully_played : bool; resume_position_ms : int }
[@@deriving yojson]
