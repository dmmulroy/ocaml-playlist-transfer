type artwork (* TODO *)
type play_params (* TODO *)
type track_types (* TODO *)

type attributes = {
  artwork : artwork option;
  can_edit : bool; [@key "canEdit"]
  date_added : string option; [@key "dateAdded"]
  description : string option;
  has_catalog : bool; [@key "hasCatalog"]
  name : string;
  play_params : play_params option; [@key "playParams"]
  is_public : bool; [@key "isPublic"]
  track_types : track_types list; [@key "trackTypes"]
}

type t = {
  id : string;
  resource_type : string; [@key "type"] (* TODO: Create Resource.t *)
  href : Http.Uri.t;
  attributes : attributes;
}
