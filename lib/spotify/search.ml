open Shared
open Syntax
open Let

type t = { tracks : Track.t Page.t } [@@deriving yojson { strict = false }]

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

module Search_input = struct
  type t = {
    query : (string * filter) list;
    search_types : search_type list;
    limit : int option;
    offset : int option;
  }

  let to_query_params t =
    let formatted_query =
      List.fold_left
        (fun acc (query, filter) ->
          acc ^ Fmt.str "%s:%s%a" (filter_to_string filter) query Fmt.sp ())
        "" t.query
    in
    let formatted_search_types =
      List.map search_type_to_string t.search_types |> String.concat ","
    in
    [ ("q", formatted_query); ("type", formatted_search_types) ]

  let make ?limit ?offset ~query ~search_types () =
    Spotify_rest_client.Request.make { query; search_types; limit; offset }
end

module Search = Spotify_rest_client.Make (struct
  type input = Search_input.t Spotify_rest_client.Request.t
  type output = t Spotify_rest_client.Response.t

  let name = "search"
  let endpoint = Http.Uri.of_string "https://api.spotify.com/v1/search"

  let make_endpoint (request : input) =
    Http.Uri.with_query' endpoint (Search_input.to_query_params request.input)

  let to_http_request request =
    let uri = make_endpoint request in
    print_endline (Http.Uri.to_string uri);
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response http_response =
    let+ search_results =
      Spotify_rest_client.handle_response ~deserialize:of_yojson http_response
    in
    let page =
      if Option.is_some search_results.tracks.next then
        let track_page = search_results.tracks in
        Option.some
        @@ Spotify_rest_client.Pagination.make
             ~next:
               {
                 href = track_page.href;
                 limit = track_page.limit;
                 offset = track_page.offset;
                 total = track_page.total;
               }
             ()
      else None
    in
    Lwt.return_ok @@ Spotify_rest_client.Response.make ?page search_results
end)

let search = Search.request
