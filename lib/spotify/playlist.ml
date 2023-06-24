type t = {
  collaborative : bool;
  description : string option;
  external_urls : External_urls.t;
  followers : Resource_reference.t;
  href : Http.Uri.t;
  id : string;
  images : Image.t list;
  name : string;
  owner : User.t;
  public : bool option;
  resource_type : string; [@key "type"]
  snapshot_id : string;
  tracks : Playlist_track.t Page.t;
  uri : string;
}
[@@deriving yojson]
