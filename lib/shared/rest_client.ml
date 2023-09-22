open Syntax
open Let
module Shared_error = Error

module Config = struct
  module type S = sig
    type api_client

    module Error : Error.S

    val headers_of_api_client : api_client -> Http.Header.t
    (* val reauthenticate : api_client -> (api_client, Shared_error.t) Lwt_result.t *)
  end
end

module Api_request = struct
  module type S = sig
    type input
    type output

    val name : string
    val to_http_request : input -> (Http.Request.t, Error.t) Lwt_result.t
    val of_http_response : Http.Response.t -> (output, Error.t) Lwt_result.t
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
  let handle_request ?client ~input ~to_http_request ~of_http_response () =
    let+ request = to_http_request input in
    let base_headers =
      Http.Header.(
        add_unless_exists
          (Http.Request.headers request)
          (of_list [ ("Content-Type", "application/json") ]))
    in
    let headers' =
      Option.fold ~none:base_headers
        ~some:(fun client' ->
          Http.Header.add_unless_exists base_headers
            (C.headers_of_api_client client'))
        client
    in
    let* response = execute (Http.Request.set_headers request headers') in
    let result =
      match response with
      | response' when Http.Response.is_success response' ->
          of_http_response response'
      (* TODO: Handle unauthenticated w/ a retry/refresh of auth token *)
      (* | response' *)
      (*   when Http.Response.status response' |> Http.Code.code_of_status = 401 -> *)
      (*     let| client' = *)
      (*       Option.to_result *)
      (*         ~none: *)
      (*           (C.Error.make ~source:(`Source "Auth - Attempt Refresh") *)
      (*              "Not implemented") *)
      (*         client *)
      (*     in *)
      (*     let+ reauthenticated_client = C.reauthenticate client' in *)
      (*     let _headers' = *)
      (*       Http.Header.add_unless_exists base_headers *)
      (*         (C.headers_of_api_client reauthenticated_client) *)
      (*     in *)
      (*     failwith "Not implemented" *)
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
      let source = `Serialization (`Raw json_str) in
      Lwt.return @@ C.Error.make ~source msg
    in
    match deserialize json with
    | Ok response -> Lwt.return_ok response
    | Error msg ->
        Lwt.return_error
        @@ C.Error.make ~source:(`Serialization (`Json json)) msg

  module Make (M : Api_request.S) = struct
    open Infix.Lwt_result

    let request ~client input =
      handle_request ~client ~input ~to_http_request:M.to_http_request
        ~of_http_response:M.of_http_response ()
      >|? fun err ->
      C.Error.make ~cause:err ~source:(`Source M.name)
      @@ "Error executing request: " ^ M.name

    (*
      let paginated_request ~clinet input =
        ...
      ((M.output, { next_page: Some fn, previous_page: Some fn }, Error.t) Lwt_result.t
     *)
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
