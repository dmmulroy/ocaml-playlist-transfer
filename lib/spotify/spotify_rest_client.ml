[@@@ocaml.warning "-32"]

open Shared

module Config :
  Rest_client.Config.S
    with type api_client = Client.t
     and type 'a page = 'a Page.t = struct
  type 'a page = 'a Page.t [@@deriving yojson]
  type api_client = Client.t

  type 'a interceptor =
    (?client:api_client -> 'a -> ('a, Error.t) Lwt_result.t) option

  module Error = Spotify_error

  let rate_limit_unit = Rest_client.Seconds

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
                 ])
        in
        Lwt.return_ok updated_request

  let intercept_response = None
  let intercept_request = Some set_headers
end

include Rest_client.Make (Config)

let pagination_of_page (page : 'a Page.t) =
  let open Page in
  let next = if Option.is_some page.next then Some page else None in
  let previous = if Option.is_some page.previous then Some page else None in
  Pagination.make ?next ?previous ()
