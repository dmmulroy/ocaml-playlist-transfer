type t = {
  id : string;
  name : string;
  url : Uri.t;
  source : [ `Spotify | `Apple ];
  target : [ `Spotify | `Apple ];
  transferred_track_count : int;
  skipped_track_ids : string list;
  timestamp : Ptime.t;
}
