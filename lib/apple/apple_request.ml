open Syntax
open Let

module type S = sig
  type input
  type output [@@deriving of_yojson]

  val name : string
  val to_http_request : input -> Http.Request.t
  val of_http_response : Http.Response.t -> (output, Error.t) Lwt_result.t
end

let execute ({ meth; headers; uri; body } : Http.Request.t) =
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

let internal_of_http_response (response : Http.Response.t) ~deserialize =
  let open Infix.Lwt_result in
  let* body_is_empty = Http.Body.is_empty @@ Http.Response.body response in
  if body_is_empty then Lwt.return_ok ()
  else
    let+ json =
      Http.Response.body response |> Http.Body.to_yojson >|?* fun (`Msg msg) ->
      let* json_str = Http.Body.to_string @@ Http.Response.body response in
      let source = `Serialization (`Raw json_str) in
      Lwt.return @@ Error.Apple.make ~source msg
    in
    match deserialize json with
    | Ok response -> Lwt.return_ok response
    | Error msg ->
        Lwt.return_error
        @@ Error.Apple.make ~source:(`Serialization (`Json json)) msg

let internal_request ~name ~input ~to_http_request ~of_http_response () =
  let request = to_http_request input in
  let headers' =
    Http.Header.add_unless_exists
      (Http.Request.headers request)
      "Content-Type" "application/json"
  in
  let* response = execute { request with headers = headers' } in
  let result =
    match response with
    | response' when Http.Response.is_success response' ->
        of_http_response response'
    | response' ->
        let request_method = Http.Request.meth request in
        let request_uri = Http.Request.uri request in
        let response_status = Http.Response.status response' in
        let message = Http.Code.reason_phrase_of_status_code response_status in
        Lwt.return_error
        @@ Error.Apple.make
             ~source:(`Http (response_status, request_method, request_uri))
             message
  in
  Infix.Lwt_result.(
    result >|? fun err ->
    Error.Apple.make ~cause:err ~source:(`Source name)
    @@ "Error executing request: " ^ name)

module Make_unauthenticated (M : S) = struct
  let request input =
    internal_request ~name:M.name ~input ~to_http_request:M.to_http_request
      ~of_http_response:M.of_http_response ()
end

let default_of_http_response ~deserialize =
  internal_of_http_response ~deserialize
