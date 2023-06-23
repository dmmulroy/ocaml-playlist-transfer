type t = {
  album_group : [ `Album | `Single | `Compilation | `Appears_on ] option;
  album_type : [ `Album | `Single | `Compilation ];
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
  release_date_precision : [ `Year | `Month | `Day ];
  resource_type : [ `Album ];
  restrictions : Common.restriction list option;
  total_tracks : int;
  (* tracks : Track.t list; (* TODO: Make Track.simple *) *)
  uri : [ `Album ] Resource.uri;
}
[@@deriving yojson]

module Simple : sig
  type t = {
    album_group : [ `Album | `Single | `Compilation | `Appears_on ] option;
    album_type : [ `Album | `Single | `Compilation ];
    artists : Artist.Simple.t list;
    available_markets : string list;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    name : string;
    release_date : string;
    release_date_precision : [ `Year | `Month | `Day ];
    restrictions : Common.restriction list option;
    total_tracks : int;
    resource_type : [ `Album ];
    uri : [ `Album ] Resource.uri;
  }
  [@@deriving yojson]
end
