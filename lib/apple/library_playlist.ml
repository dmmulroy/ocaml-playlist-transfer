type artwork = unit option (* TODO *) [@@deriving yojson]
type track_types = unit option (* TODO *) [@@deriving yojson]
type description = { standard : string } [@@deriving yojson { strict = false }]

type play_params = {
  id : string;
  kind : string;
  is_library : bool; [@key "isLibrary"]
}
[@@deriving yojson { strict = false }]

type attributes = {
  last_modified_date : string; [@key "lastModifiedDate"]
  can_edit : bool; [@key "canEdit"]
  name : string;
  (* description : description option; *)
  is_public : bool; [@key "isPublic"]
  has_catalog : bool; [@key "hasCatalog"]
  play_params : play_params; [@key "playParams"]
  date_added : string; [@key "dateAdded"]
}
[@@deriving yojson { strict = false }]

type t = {
  id : string;
  resource_type : Resource.t; [@key "type"]
  href : string;
  attributes : attributes;
}
[@@deriving yojson { strict = false }]

module Get_all_playlists_input = struct
  type t = unit
end

module Get_all_playlists_output = struct
  type playlist = t [@@deriving yojson { strict = false }]
  type meta = { total : int } [@@deriving yojson { strict = false }]

  type t = { data : playlist list; meta : meta }
  [@@deriving yojson { strict = false }]
end

module Get_all_playlists = Apple_request.Make (struct
  type input = Get_all_playlists_input.t

  type output = Get_all_playlists_output.t
  [@@deriving yojson { strict = false }]

  let name = "Get_all_playlists"

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:endpoint input

  let of_http_response =
    Apple_request.default_of_http_response ~deserialize:output_of_yojson
end)

let get_all_playlists = Get_all_playlists.request
