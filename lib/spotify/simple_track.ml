type t = {
  artists : Simple_artist.t list;
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option;
  linked_from : Track.linked_track option;
  name : string;
  preview_url : string option;
  resource_type : Resource.t; [@key "type"]
  restrictions : Common.restriction list option;
  track_number : int;
  uri : string;
}
[@@deriving yojson]
