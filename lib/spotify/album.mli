type restrictions = { reason : [ `Market | `Product | `Explicit ] }

type t = {
  album_group : [ `Album | `Single | `Compilation | `Appears_on ] option;
  album_type : [ `Album | `Single | `Compilation ];
  artists : Artist.t list;
  available_markets : string list;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  release_date : string;
  release_date_precision : [ `Year | `Month | `Day ];
  restrictions : restrictions list option;
  total_tracks : int;
  resource_type : [ `Album ];
  uri : Uri.t;
}
[@@deriving yojson]
