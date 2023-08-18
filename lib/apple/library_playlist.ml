type artwork = unit option (* TODO *) [@@deriving yojson]
type play_params = unit option (* TODO *) [@@deriving yojson]
type track_types = unit option (* TODO *) [@@deriving yojson]

type description = { short : string option; standard : string }
[@@deriving yojson]

type attributes = {
  artwork : artwork option;
  can_edit : bool; [@key "canEdit"]
  date_added : string option; [@key "dateAdded"]
  description : description;
  has_catalog : bool; [@key "hasCatalog"]
  name : string;
  play_params : play_params option; [@key "playParams"]
  is_public : bool; [@key "isPublic"]
  track_types : track_types list; [@key "trackTypes"]
}
[@@deriving yojson]

type t = {
  id : string;
  resource_type : Resource.t; [@key "type"]
  href : Http.Uri.t;
  attributes : attributes;
}
[@@deriving yojson]

module Get_all_playlists_input = struct
  type t = unit
end

module Get_all_playlists_output = struct
  type playlist = t [@@deriving yojson]
  type t = { data : playlist } [@@deriving yojson]
end

module Get_all_playlists = Apple_request.Make (struct
  type input = Get_all_playlists_input.t
  type output = Get_all_playlists_output.t [@@deriving yojson]

  let name = "Get_all_playlists"

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:endpoint input

  let of_http_response =
    Apple_request.default_of_http_response ~deserialize:output_of_yojson
end)

let get_all_playlists = Get_all_playlists.request