type t = {
  display_name : string option;
  external_urls : External_urls.t;
  followers : Resource_reference.t option;
  href : Http.Uri.t;
  id : string;
  image : Image.t list option;
  resource_type : string;
  uri : string;
}
[@@deriving yojson]
