open Syntax

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

type relationships

type t = {
  attributes : attributes;
  href : string;
  id : string;
  resource_type : Resource.t; [@key "type"]
}
[@@deriving yojson { strict = false }]

module Get_all_input = struct
  type t = unit
end

module Get_all_output = struct
  type playlist = t [@@deriving yojson]
  type t = playlist Page.t [@@deriving yojson]
end

module Get_all = Apple_request.Make (struct
  type input = Get_all_input.t
  type output = Get_all_output.t [@@deriving yojson { strict = false }]

  let name = "Get_all"

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:endpoint input

  let of_http_response =
    Apple_request.handle_response ~deserialize:output_of_yojson
end)

let get_all = Get_all.request

module Get_by_id_input = struct
  type t = {
    id : string;
    extended_attributes : [ `Track_types ] option;
    relationships : [ `Tracks | `Catalog ] list option;
  }
  [@@deriving make]

  let extended_attributes_to_string = function `Track_types -> "trackTypes"

  let to_query_params input =
    let open Infix.Option in
    List.filter_map
      (fun (key, value) -> value >|= fun value -> (key, value))
      [
        ( "include",
          input.relationships >|= Relationship.to_string_list
          >|= String.concat "," );
        ("extend", input.extended_attributes >|= extended_attributes_to_string);
      ]
end

module Get_by_id_output = struct
  type playlist = t [@@deriving yojson]
  type t = { data : playlist list } [@@deriving yojson]
end

module Get_by_id = Apple_request.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t [@@deriving yojson]

  let name = "Get_by_id"

  let make_endpoint (input : input) =
    let base_endpoint =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/playlists/%s" input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params input

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response =
    Apple_request.handle_response ~deserialize:output_of_yojson
end)

let get_by_id = Get_by_id.request
