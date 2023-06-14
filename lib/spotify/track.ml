type t_old = {
  added_at : string;
  added_by : User.t;
  external_urls : Common.external_urls;
  followers : Resource_type.reference;
  is_local : bool;
}
[@@deriving yojson { strict = false }]

type t = {
  album : unit; (* TODO *)
  artists : unit list; (* TODO *)
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool;
  linked_from : unit option; (* TODO *)
  name : string;
  popularity : int;
  preview_url : string option; (* nullable *)
  resource_type : [ `Track ];
      [@key "type"]
      [@of_yojson Resource_type.track_of_yojson]
      [@to_yojson Resource_type.track_to_yojson]
  track_number : int;
  uri : string;
}
[@@deriving yojson { strict = false }]
