type t = {
  catalog_id : string option; [@default None]
  id : string;
  is_library : bool; [@key "isLibrary"]
  kind : Resource.t;
  reporting : bool option; [@default None]
  reporting_id : string option; [@default None]
}
[@@deriving yojson]
