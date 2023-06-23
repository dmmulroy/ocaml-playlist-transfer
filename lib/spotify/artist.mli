type t = {
  external_urls : Common.external_urls;
  followers : Common.reference;
  genres : string list;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  popularity : int;
  resource_type : Resource.t;
  uri : Resource.uri;
}
[@@deriving yojson]

module Simple : sig
  type t = {
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    name : string;
    resource_type : Resource.t;
    uri : Resource.uri;
  }
  [@@deriving yojson]
end
