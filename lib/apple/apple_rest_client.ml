[@@@ocaml.warning "-26-27-32"]

open Shared
open Syntax
open Let

module Config :
  Rest_client.Config.S
    with type api_client = Client.t
    with type 'a page = 'a Types.Page.t = struct
  type api_client = Client.t
  type 'a page = 'a Types.Page.t [@@deriving yojson]

  type 'a interceptor =
    (?client:api_client -> 'a -> ('a, Error.t) Lwt_result.t) option

  module Error = Apple_error

  let rate_limit_unit = Rest_client.Miliseconds

  let set_headers ?(client : api_client option) (request : Http.Request.t) =
    match client with
    | None -> Lwt.return_ok request
    | Some client ->
        let headers = Http.Request.headers request in
        let updated_request =
          Http.Request.set_headers request
            (Http.Header.add_unless_exists headers
            @@ Http.Header.of_list
                 [
                   ( "Authorization",
                     Fmt.str "Bearer %s" @@ Client.get_bearer_token client );
                   ("Music-User-Token", Client.music_user_token client);
                 ])
        in
        Lwt.return_ok updated_request

  let intercept_response = None
  let intercept_request = Some set_headers
end

include Rest_client.Make (Config)

(* let pagination_of_page (page : 'a Page.t) =
   let open Page in
   let _next = if Option.is_some page.next then page.next else None in
   let limit = page.data |> List.length in
   let _previous = Page.previous_of_path ~limit page.next in
   failwith "" *)
(* Pagination.make ?next ~previous () *)

let base_endpoint = Uri.of_string "https://api.music.apple.com/v1"

(* type 'a t = { next : 'a page option; previous : 'a page option } *)
let pagination_of_page_v2 (page : 'a Types.Page.t) =
  let@ href =
    page.href
    |> Option.to_result
         ~none:
           (Apple_error.make
              ~source:(`Source "Apple_rest_client.pagination_of_page")
              "page.href is required")
  in
  let items = page.data in
  let@ { total } =
    page.meta
    |> Option.to_result
         ~none:
           (Apple_error.make
              ~source:(`Source "Apple_rest_client.pagination_of_page")
              "page.meta is required")
  in
  let limit = List.length items in

  (* let@ offset =  *)
  let meta : Pagination_v2.Page.meta = { total; limit; offset = 0 } in

  failwith ""
(* Pagination.make ?next ~previous () *)
