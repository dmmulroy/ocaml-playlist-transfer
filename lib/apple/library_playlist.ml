type description = { standard : string; short : string option [@default None] }
[@@deriving yojson]

type track_types = Resource.t list [@@deriving yojson]

type attributes = {
  artwork : Artwork.t option; [@default None]
  can_edit : bool; [@key "canEdit"]
  date_added : string; [@key "dateAdded"]
  description : description option; [@default None]
  has_catalog : bool; [@key "hasCatalog"]
  is_public : bool; [@key "isPublic"]
  last_modified_date : string; [@key "lastModifiedDate"]
  name : string;
  play_params : Play_params.t; [@key "playParams"]
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
  type playlist = t [@@deriving yojson]
  type t = playlist Page.t [@@deriving yojson]
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
    Apple_request.handle_response ~deserialize:output_of_yojson
end)

let get_all_playlists = Get_all_playlists.request
