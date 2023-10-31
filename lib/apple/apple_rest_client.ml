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

let base_endpoint = Uri.of_string "https://api.music.apple.com/v1"

let pagination_of_page page =
  let open Types in
  let@ href =
    Page.href page
    |> Option.to_result
         ~none:
           (Apple_error.make
              ~source:(`Source "Apple_rest_client.pagination_of_page")
              "page.href or page.next is required")
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
  let limit = Page.limit page in
  let offset = Page.offset page in
  let next =
    page.next
    |> Option.map (fun next ->
           Pagination_v2.Page.make ~href:next ~limit ~offset ~total ())
  in
  let previous =
    Page.previous page
    |> Option.map (fun previous ->
           Pagination_v2.Page.make ~href:previous ~limit ~offset ~total ())
  in
  Ok (Pagination_v2.make ?next ?previous ())
