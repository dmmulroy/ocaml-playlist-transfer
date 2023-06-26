type album_type = [ `Album | `Single | `Compilation ] [@@deriving yojson]
type album_group = [ album_type | `Appears_on ] [@@deriving yojson]

type t = {
  album_group : album_group option;
  album_type : album_type;
  artists : Artist.t list;
  available_markets : string list;
  copyrights : Common.copyright list;
  external_urls : Common.external_urls;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  label : string;
  name : string;
  popularity : int;
  release_date : string;
  release_date_precision : Common.release_date_precision;
  resource_type : Resource.t;
  restrictions : Common.restriction list option;
  total_tracks : int;
  tracks : Simple_track.t list;
  uri : string;
}
[@@deriving yojson]
