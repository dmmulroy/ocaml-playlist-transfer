open Shared
open Syntax
open Let

type t = { tracks : Types.Track.t Page.t }
[@@deriving yojson { strict = false }]

type filter =
  [ `Album
  | `Artist
  | `Playlist
  | `Track
  | `Year
  | `Upc
  | `Tag_hipster
  | `Tag_new
  | `Isrc
  | `Genre ]

let filter_to_string = function
  | `Album -> "album"
  | `Artist -> "artist"
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `Year -> "year"
  | `Upc -> "upc"
  | `Tag_hipster -> "tag:hipster"
  | `Tag_new -> "tag:new"
  | `Isrc -> "isrc"
  | `Genre -> "genre"
  | #filter -> .

let filter_of_string = function
  | "album" -> Ok `Album
  | "artist" -> Ok `Artist
  | "playlist" -> Ok `Playlist
  | "track" -> Ok `Track
  | "year" -> Ok `Year
  | "upc" -> Ok `Upc
  | "tag:hipster" -> Ok `Tag_hipster
  | "tag:new" -> Ok `Tag_new
  | "isrc" -> Ok `Isrc
  | "genre" -> Ok `Genre
  | _ -> Error "Invalid filter"

let filter_of_yojson = function
  | `String filter -> filter_of_string filter
  | _ -> Error "Invalid search filter"

(* let filter_of_yojson_narrowed ~(narrow : filter -> ([< filter ], string) result)
     json =
   Infix.Result.(filter_of_yojson json >>= narrow) *)

let filter_to_yojson filter = `String (filter_to_string filter)

type search_type =
  [ `Album | `Artist | `Audiobook | `Episode | `Playlist | `Track | `Show ]

let search_type_to_string = function
  | `Album -> "album"
  | `Artist -> "artist"
  | `Audiobook -> "audiobook"
  | `Episode -> "episode"
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `Show -> "show"
  | #search_type -> .

let search_type_of_string = function
  | "album" -> Ok `Album
  | "artist" -> Ok `Artist
  | "audiobook" -> Ok `Audiobook
  | "episode" -> Ok `Episode
  | "playlist" -> Ok `Playlist
  | "track" -> Ok `Track
  | "show" -> Ok `Show
  | _ -> Error "Invalid search type"

let search_type_of_yojson = function
  | `String search_type -> search_type_of_string search_type
  | _ -> Error "Invalid search type"

let search_type_to_yojson search_type =
  `String (search_type_to_string search_type)

module Search = struct
  let name = "search"

  type input = {
    query : (string * filter) list;
    search_types : search_type list;
    limit : int option;
    offset : int option;
  }

  let input_to_query_params input =
    let formatted_query =
      List.fold_left
        (fun acc (query, filter) ->
          acc ^ Fmt.str "%s:%s%a" (filter_to_string filter) query Fmt.sp ())
        "" input.query
    in
    let formatted_search_types =
      List.map search_type_to_string input.search_types |> String.concat ","
    in
    [
      ("q", Some formatted_query);
      ("type", Some formatted_search_types);
      ("limit", Option.map string_of_int input.limit);
      ("offset", Option.map string_of_int input.offset);
    ]
    |> List.filter_map (fun (key, value) ->
           Option.map (fun value' -> (key, value')) value)

  type output = t

  let endpoint = Http.Uri.of_string "https://api.spotify.com/v1/search"

  let make_endpoint (request : input) =
    Http.Uri.with_query' endpoint (input_to_query_params request)

  let to_http_request request =
    let uri = make_endpoint request in
    print_endline (Http.Uri.to_string uri);
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response http_response =
    Spotify_rest_client.handle_response ~deserialize:of_yojson http_response
end

let search ~client
    ?(page : [ `Next of 'a Page.t | `Previous of 'a Page.t ] option) ~query
    ~search_types () =
  let open Search in
  let open Page in
  let module Request = Spotify_rest_client.Make (Search) in
  let limit, offset =
    match page with
    | None -> (None, None)
    | Some (`Next page) -> Page.limit_and_offset (`Next page)
    | Some (`Previous page) -> Page.limit_and_offset (`Previous page)
  in
  let request = { query; search_types; limit; offset } in
  let+ { tracks } = Request.request ~client request in
  let pagination = Spotify_rest_client.pagination_of_page tracks in
  Lwt.return_ok
  @@ Spotify_rest_client.Response.Paginated.make pagination tracks.items
