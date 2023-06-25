type t = {
  album_group : Album.album_group option; [@default None]
  album_type : Album.album_type;
  artists : Simple_artist.t list;
  available_markets : string list;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  release_date : string;
  release_date_precision : Album.release_date_precision;
  restrictions : Common.restriction list option; [@default None]
  total_tracks : int;
  resource_type : Resource.t; [@key "type"]
  uri : string;
}
[@@deriving yojson]
