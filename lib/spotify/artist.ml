type restrictions = { reason : string }

type t = {
  album_type : [ `Album | `Single | `Compilation ];
  total_tracks : int;
  available_markets : string list;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  release_date : string;
  release_date_precision : [ `Year | `Month | `Day ];
  restrictions : restrictions option;
  resource_type : [ `Album ];
  uri : string;
}
