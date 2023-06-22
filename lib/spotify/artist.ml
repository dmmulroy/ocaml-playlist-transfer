type resource_type = [ `Artist ] [@@deriving yojson]

let resource_type_of_yojson = Common.make_resource_type_of_yojson Artist
let resource_type_to_yojson = Common.make_resource_type_to_yojson Artist

type simple = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  name : string;
  resource_type : resource_type; [@key "type"]
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
  resource_type : resource_type; [@key "type"]
  uri : Uri.t;
}
[@@deriving yojson]
