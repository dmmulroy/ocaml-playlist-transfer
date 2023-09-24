open Shared

type t = {
  (* album : Simple_album.t; *)
  (* artists : Simple_artist.t list; *)
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  episode : bool;
  explicit : bool;
  external_ids : Common.external_ids;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option; [@default None]
  (* linked_from : Common.linked_track option; [@default None] *)
  name : string;
  popularity : int;
  preview_url : string option; [@default None]
  resource_type : Resource.t; [@key "type"]
  (* restrictions : Common.restriction list option; [@default None] *)
  track : bool;
  track_number : int;
  uri : string;
}
[@@deriving yojson { strict = false }]
