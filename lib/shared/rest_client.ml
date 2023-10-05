open Syntax
open Let

module Config = struct
  module type S = sig
    type api_client
    type cursor [@@deriving yojson]

    module Error : Error.S

    type 'a interceptor =
      (?client:api_client -> 'a -> ('a, Error.t) Lwt_result.t) option

    type rate_limit_unit = Miliseconds | Seconds

    val rate_limit_unit : rate_limit_unit
    val intercept_request : Http.Request.t interceptor
    val intercept_response : Http.Response.t interceptor
  end
end

module Api_request = struct
  module Config = struct
    module type S = sig
      type input
      type output

      val make_input : 'a -> input
      val name : string
      val to_http_request : input -> (Http.Request.t, Error.t) Lwt_result.t
      val of_http_response : Http.Response.t -> (output, Error.t) Lwt_result.t
    end
  end

  module type S = sig
    include Config.S

    val execute : client:'api_client -> input -> (output, Error.t) Lwt_result.t
    val execute_unauthenticated : input -> (output, Error.t) Lwt_result.t
    val make_request : 'a -> input
  end
end

module type S = sig
  include Config.S

  val handle_request :
    ?client:api_client ->
    input:'a ->
    to_http_request:('a -> (Http.Request.t, Error.t) Lwt_result.t) ->
    of_http_response:(Http.Response.t -> ('b, Error.t) Lwt_result.t) ->
    unit ->
    ('b, Error.t) Lwt_result.t

  val handle_response :
    deserialize:(Yojson.Safe.t -> ('a, string) result) ->
    Http.Response.t ->
    ('a, Error.t) Lwt_result.t

  module Pagination : sig
    type nonrec cursor = cursor

    val cursor_to_yojson : cursor -> Yojson.Safe.t

    val cursor_of_yojson :
      Yojson.Safe.t -> cursor Ppx_deriving_yojson_runtime.error_or

    type t = { next : cursor option; previous : cursor option }

    val to_yojson : t -> Yojson.Safe.t
    val of_yojson : Yojson.Safe.t -> t Ppx_deriving_yojson_runtime.error_or
    val make : ?next:cursor -> ?previous:cursor -> unit -> t
    val empty : t
  end

  module Request : sig
    type 'a t = { input : 'a; page : cursor option }

    val make : ?page:cursor -> 'a -> 'a t
  end

  module Response : sig
    type 'a t = { data : 'a; page : Pagination.t }

    val to_yojson : ('a -> Yojson.Safe.t) -> 'a t -> Yojson.Safe.t

    val of_yojson :
      (Yojson.Safe.t -> 'a Ppx_deriving_yojson_runtime.error_or) ->
      Yojson.Safe.t ->
      'a t Ppx_deriving_yojson_runtime.error_or

    val make : ?page:Pagination.t -> 'a -> 'a t
  end

  module Make : functor (M : Api_request.S) -> sig
    val request :
      client:api_client -> M.input -> (M.output, Error.t) Lwt_result.t
  end

  module Make_unauthenticated : functor (M : Api_request.S) -> sig
    val request : M.input -> (M.output, Error.t) Lwt_result.t
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
    type cursor = C.cursor [@@deriving yojson]

    type t = { next : cursor option; previous : cursor option }
    [@@deriving yojson]

    let make ?next ?previous () = { next; previous }
    let empty = { next = None; previous = None }
  end

  module Request = struct
    type 'a t = { input : 'a; page : Pagination.cursor option }

    let make ?page input = { input; page }
  end

  module Response = struct
    type 'a t = { data : 'a; page : Pagination.t } [@@deriving yojson]

    let make ?(page = Pagination.empty) data = { data; page }
  end

  module Make (M : Api_request.S) = struct
    open Infix.Lwt_result

    let request ~client input =
      handle_request ~client ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name
  end

  module Make_v2 (M : Api_request.Config.S) = struct
    open Infix.Lwt_result

    let execute ~client input =
      handle_request ~client ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name

    let execute_unauthenticated input =
      handle_request ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name

    let make_request = M.make_input
  end

  module Make_unauthenticated (M : Api_request.S) = struct
    open Infix.Lwt_result

    let request input =
      handle_request ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name
  end
end
