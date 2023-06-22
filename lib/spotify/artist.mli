type simple = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  name : string;
  resource_type : [ `Artist ];
  uri : Uri.t;
}
[@@deriving yojson]

type t = {
  external_urls : Common.external_urls;
  followers : Common.reference;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  popularity : int;
  resource_type : [ `Artist ];
  uri : Uri.t;
}
[@@deriving yojson]
