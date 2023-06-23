type t = {
  external_urls : Common.external_urls;
  followers : [ `Follower ] Resource.reference;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  popularity : int;
  resource_type : [ `Artist ] Resource.t; [@key "type"]
  uri : [ `Artist ] Resource.uri;
}
[@@deriving yojson]

module Simple = struct
  type t = {
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    name : string;
    resource_type : [ `Artist ] Resource.t; [@key "type"]
    uri : [ `Artist ] Resource.uri;
  }
  [@@deriving yojson]
end
