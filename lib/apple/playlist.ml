type attributes = {
  artwork : Artwork.t option; [@default None]
  curator_name : string; [@key "curatorName"]
  is_chart : bool; [@key "isChart"]
  description : Description.t option; [@default None]
  last_modified_date : string option; [@key "lastModifiedDate"] [@default None]
  name : string;
  playlist_type :
    [ `Editoral | `External | `Personal_mix | `Replay | `User_shared ];
      [@key "playlistType"]
  play_params : Play_params.t option; [@key "playParams"] [@default None]
  track_types : Resource.t list option; [@key "trackTypes"] [@default None]
  url : Http.Uri.t;
}
[@@deriving yojson]

(* TODO *)
(* type realationships = { *)
(*   tracks:  *)
(* } *)

type t = {
  id : string;
  href : string;
  resource_type : Resource.t; [@key "type"]
  attributes : unit;
  realationships : unit option; [@default None]
  views : unit option; [@default None]
}
[@@deriving yojson]
