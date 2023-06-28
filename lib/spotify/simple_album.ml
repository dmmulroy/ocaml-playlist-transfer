type t = {
  album_group : Album.album_group option; [@default None]
  album_type : Album.album_type;
  artists : Simple_artist.t list;
  available_markets : string list;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  is_playable : bool option; [@default None]
  name : string;
  release_date : string option; [@default None]
  release_date_precision : Common.release_date_precision option; [@default None]
  restrictions : Common.restriction option; [@default None]
  total_tracks : int;
  resource_type : Resource.t; [@key "type"]
  uri : string;
}
[@@deriving yojson]
