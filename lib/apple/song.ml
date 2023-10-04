open Shared
open Syntax
open Let

(* TODO: this *)
module Internal_error = struct
  type t
end

module Get_by_id_input = struct
  type t = string

  let make id = id
end

module Get_by_id_output = struct
  type t = { data : Types.Song.t list } [@@deriving yojson { strict = false }]
end

module Get_by_id = Apple_rest_client.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t [@@deriving yojson { strict = false }]

  let name = "Get_by_id"

  let to_http_request input =
    let uri =
      Http.Uri.of_string
        ("https://api.music.apple.com/v1/catalog/us/songs/" ^ input)
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_by_id = Get_by_id.request

module Get_many_by_isrcs_input = struct
  type t = string list

  let to_query_params input = [ ("filter[isrc]", String.concat "," input) ]
end

module Get_many_by_isrcs_output = struct
  type isrc_response = {
    id : string;
    resource_type : [ `Songs ];
        [@key "type"]
        [@to_yojson Resource.to_yojson]
        [@of_yojson
          Resource.of_yojson_narrowed ~narrow:Types.Song.narrow_resource_type]
    href : string;
  }
  [@@deriving yojson { exn = true }]

  let isrc_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Assoc assoc_list ->
        let extract_playlists (key, value) =
          match value with
          | `List playlists ->
              Some (key, List.map isrc_response_of_yojson_exn playlists)
          | _ -> None
        in
        let results = List.filter_map extract_playlists assoc_list in
        if List.length results = List.length assoc_list then Ok results
        else Error "expected list of isrc_responses for every key"
    | _ -> Error "expected an association list of playlists"

  type filters = {
    isrc : (string * isrc_response list) list; [@of_yojson isrc_of_yojson]
  }
  [@@deriving yojson]

  type meta = { filters : filters [@of_yojson filters_of_yojson] }
  [@@deriving yojson]

  type t = { data : Types.Song.t list; meta : meta }
  [@@deriving yojson { strict = false }]
end

module Get_many_by_isrcs = Apple_rest_client.Make (struct
  type input = Get_many_by_isrcs_input.t

  type output = Get_many_by_isrcs_output.t
  [@@deriving yojson { strict = false }]

  let name = "Get_songs_by_isrc"

  let to_http_request input =
    let base_endpoint =
      Http.Uri.of_string "https://api.music.apple.com/v1/catalog/us/songs/"
    in
    let uri =
      Http.Uri.add_query_params' base_endpoint
      @@ Get_many_by_isrcs_input.to_query_params input
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_many_by_isrcs ~(client : Client.t) (input : Get_many_by_isrcs_input.t) =
  let chunked_isrcs = Extended.List.chunk 25 input in
  let promises = List.map (Get_many_by_isrcs.request ~client) chunked_isrcs in
  let+ result =
    let open Get_many_by_isrcs_output in
    List.fold_left
      (fun acc chunked_result ->
        let+ { data; meta } = acc in
        let+ { data = data'; meta = meta' } = chunked_result in
        let merged_data = List.append data' data in
        let merged_isrcs = List.append meta'.filters.isrc meta.filters.isrc in
        Lwt_result.return
          { data = merged_data; meta = { filters = { isrc = merged_isrcs } } })
      (Lwt_result.return { data = []; meta = { filters = { isrc = [] } } })
      promises
  in
  Lwt.return_ok result
