type artwork = {
  bg_color : string option; [@key "bgColor"]
  height : int;
  width : int;
  text_color1 : string option; [@key "textColor1"]
  text_color2 : string option; [@key "textColor2"]
  text_color3 : string option; [@key "textColor3"]
  text_color4 : string option; [@key "textColor4"]
  url : string;
}
[@@deriving yojson]

type description = { standard : string; short : string option [@default None] }
[@@deriving yojson]

type track_types = Resource.t list [@@deriving yojson]

type play_params = {
  id : string;
  is_library : bool; [@key "isLibrary"]
  kind : string;
}
[@@deriving yojson { strict = false }]

type attributes = {
  artwork : artwork option; [@default None]
  can_edit : bool; [@key "canEdit"]
  date_added : string; [@key "dateAdded"]
  description : description option; [@default None]
  has_catalog : bool; [@key "hasCatalog"]
  is_public : bool; [@key "isPublic"]
  last_modified_date : string; [@key "lastModifiedDate"]
  name : string;
  play_params : play_params; [@key "playParams"]
  track_types : track_types option; [@key "trackTypes"] [@default None]
}
[@@deriving yojson { strict = false }]

type t = {
  attributes : attributes;
  href : string;
  id : string;
  resource_type : Resource.t; [@key "type"]
}
[@@deriving yojson { strict = false }]

module Get_all_playlists_input = struct
  type t = unit
end

module Get_all_playlists_output = struct
  type playlist = t [@@deriving yojson { strict = false }]
  type meta = { total : int } [@@deriving yojson { strict = false }]

  type t = {
    data : playlist list;
    meta : meta;
    next : string option; [@default None]
  }
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
