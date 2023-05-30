type playlist_attributes = {
  name : string;
  is_public : bool;
  can_edit : bool;
  has_catalog : bool;
  description : string option;
  artwork : Common.artwork option;
  date_added : string option; (* TODO: YYYY-MM-DDThh:mm:ssZ ISO 8601 *)
}

type t = {
  id : string;
  playlist_type : [ `Library ];
  attributes : playlist_attributes option;
  tracks : Song.t list option;
}

let get_id t = t.id
let get_name t = Option.map (fun attributes -> attributes.name) t.attributes

let get_description t =
  Option.map (fun attributes -> attributes.description) t.attributes

let get_tracks t = t.tracks

let get_date_added t =
  Option.map (fun attributes -> attributes.date_added) t.attributes

let is_public t =
  Option.map (fun attributes -> attributes.is_public) t.attributes
