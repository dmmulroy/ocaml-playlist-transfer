open Syntax
open Let

type rate_limit_unit = Miliseconds | Seconds

module Config = struct
  module type S = sig
    type api_client
    type 'a page [@@deriving yojson]

    module Error : Error.S

    type 'a interceptor =
      (?client:api_client -> 'a -> ('a, Error.t) Lwt_result.t) option

    val rate_limit_unit : rate_limit_unit
    val intercept_request : Http.Request.t interceptor
  end
end

module Api_request = struct
  module Config = struct
    module type S = sig
      type input
      type output

      val name : string
      val to_http_request : input -> (Http.Request.t, Error.t) Lwt_result.t
      val of_http_response : Http.Response.t -> (output, Error.t) Lwt_result.t
    end
  end
end

let execute request =
  let meth = Http.Request.meth request in
  let uri = Http.Request.uri request in
  let headers = Http.Request.headers request in
  let body = Http.Request.body request in
  let* response, body' =
    match meth with
    | `GET -> Http.Client.get ~headers uri
    | `POST -> Http.Client.post ~headers ~body uri
    | `PUT -> Http.Client.put ~headers ~body uri
    | `DELETE -> Http.Client.delete ~headers ~body uri
  in
  Lwt.return
  @@ Http.Response.make ~headers:response.headers ~body:body'
       ~status:response.status ()

module Make (C : Config.S) = struct
  let rec handle_request ?client ~input ~to_http_request ~of_http_response () =
    let+ request =
      Infix.Lwt_result.(
        to_http_request input >>= fun request ->
        match C.intercept_request with
        | None -> Lwt.return_ok request
        | Some interceptor -> interceptor ?client request)
    in
    let headers =
      Http.Header.(
        add_unless_exists
          (Http.Request.headers request)
          (of_list [ ("Content-Type", "application/json") ]))
    in
    let* response = execute (Http.Request.set_headers request headers) in
    let result =
      match response with
      | response' when Http.Response.is_success response' ->
          let+ result = of_http_response response' in
          Lwt.return_ok result
      | response'
        when Http.Code.code_of_status @@ Http.Response.status response' = 429
        -> (
          let request_method = Http.Request.meth request in
          let request_uri = Http.Request.uri request in
          let response_headers = Http.Response.headers response' in
          let retry_after =
            Http.Header.get response_headers "Retry-After"
            |> Option.map int_of_string
          in
          match retry_after with
          | None ->
              Lwt.return_error
              @@ C.Error.make
                   ~source:
                     (`Http
                       ( Http.Code.status_of_code 429,
                         request_method,
                         request_uri ))
                   "Too many requests"
          | Some retry_after ->
              let retry_after_seconds =
                match C.rate_limit_unit with
                | Miliseconds -> float_of_int retry_after /. 1000.
                | Seconds -> float_of_int retry_after
              in
              let* _ = Lwt_unix.sleep retry_after_seconds in
              handle_request ?client ~input ~to_http_request ~of_http_response
                ())
      | response' ->
          let request_method = Http.Request.meth request in
          let request_uri = Http.Request.uri request in
          let response_status = Http.Response.status response' in
          let message =
            Http.Code.reason_phrase_of_status_code response_status
          in
          Lwt.return_error
          @@ C.Error.make
               ~source:(`Http (response_status, request_method, request_uri))
               message
    in
    result

  let handle_response ~deserialize (response : Http.Response.t) =
    let open Infix.Lwt_result in
    let+ json =
      Http.Response.body response |> Http.Body.to_yojson >|?* fun msg ->
      let* json_str = Http.Body.to_string @@ Http.Response.body response in
      let source = `Serialization (`Raw (Yojson.Safe.prettify json_str)) in
      Lwt.return @@ C.Error.make ~source msg
    in
    match deserialize json with
    | Ok response -> Lwt.return_ok response
    | Error msg ->
        Lwt.return_error
        @@ C.Error.make ~source:(`Serialization (`Json json)) msg

  module Pagination = struct
    type 'a page = 'a C.page [@@deriving yojson]

    type 'a t = { next : 'a page option; previous : 'a page option }
    [@@deriving yojson]

    let make ?next ?previous () = { next; previous }
    let empty = { next = None; previous = None }
  end

  module Pagination_v2 = struct
    module Page = struct
      type meta = { total : int; limit : int; offset : int }
      type 'a items = Fulfilled of 'a list | Unfulfilled

      type 'a t = {
        href : Http.Uri.t;
        items : 'a items;
        meta : meta;
        next : meta option;
        previous : meta option;
      }

      type 'a cursor = Current of 'a t | Next of 'a t | Previous of 'a t

      let empty =
        {
          href = Http.Uri.of_string "";
          items = Unfulfilled;
          meta = { total = 0; limit = 0; offset = 0 };
          next = None;
          previous = None;
        }

      (* TODO: Consider if we want have every field be optional *)
      let make ?(href = Http.Uri.of_string "") ?(items = Unfulfilled)
          ?(limit = 0) ?(next = None) ?(offset = 0) ?(previous = None)
          ?(total = 0) () =
        { href; items; meta = { total; limit; offset }; next; previous }

      let offset = function
        | Current page -> Some page.meta.offset
        | Next page -> Option.map (fun next -> next.offset) page.next
        | Previous page ->
            Option.map (fun previous -> previous.offset) page.previous

      let limit = function
        | Current page -> Some page.meta.limit
        | Next page -> Option.map (fun next -> next.limit) page.next
        | Previous page ->
            Option.map (fun previous -> previous.limit) page.previous

      let limit_and_offset = function
        | Current page -> (Some page.meta.limit, Some page.meta.offset)
        | Next page -> (limit (Next page), offset (Next page))
        | Previous page -> (limit (Previous page), offset (Previous page))
    end

    type 'a page = 'a Page.t
    type 'a t = { next : 'a page option; previous : 'a page option }

    let make ?next ?previous () = { next; previous }
    let empty = { next = None; previous = None }
  end

  module Response = struct
    type 'a t = { data : 'a } [@@deriving yojson]

    let make data = { data }

    module Paginated = struct
      type 'a t = { data : 'a list; pagination : 'a Pagination.t }
      [@@deriving yojson]

      let make pagination data = { data; pagination }
    end

    module Paginated_v2 = struct
      type 'a t = { data : 'a list; pagination : 'a Pagination_v2.t }

      let make pagination data = { data; pagination }
    end
  end

  module Make (M : Api_request.Config.S) = struct
    open Infix.Lwt_result

    let request ~client input =
      handle_request ~client ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name
  end

  module Make_unauthenticated (M : Api_request.Config.S) = struct
    open Infix.Lwt_result

    let request input =
      handle_request ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name
  end
end
