type t = {
  artists : Simple_artist.t list;
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_urls : External_urls.t;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option;
  linked_from : Linked_track.t option;
  name : string;
  preview_url : string option;
  resource_type : string; [@key "type"]
  restrictions : Restriction.t list option;
  track_number : int;
  uri : string;
}
[@@deriving yojson]
