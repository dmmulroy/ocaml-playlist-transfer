[@@@ocaml.warning "-69"]

type description_attribute = { standard : string; short : string option }

type playlist_attributes = {
  name : string;
  is_public : bool;
  can_edit : bool;
  has_catalog : bool;
  description : description_attribute option;
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

let get_name t =
  match t.attributes with
  | Some attributes -> Some attributes.name
  | None -> None

let get_description t =
  match t.attributes with
  | Some attributes -> (
      match attributes.description with
      | Some description -> Some description.standard
      | None -> None)
  | None -> None

let get_tracks t = t.tracks

let get_date_added t =
  match t.attributes with
  | Some attributes -> attributes.date_added
  | None -> None

let is_public t =
  match t.attributes with
  | Some attributes -> Some attributes.is_public
  | None -> None
