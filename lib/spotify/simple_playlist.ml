type t = {
  collaborative : bool;
  description : string option;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  public : bool option;
  resource_type : Resource.t; [@key "type"]
  snapshot_id : string;
  tracks : Resource.reference;
  uri : string;
}
[@@deriving yojson]
