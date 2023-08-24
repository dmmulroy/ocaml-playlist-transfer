open Syntax
open Let

module type S = sig
  type input
  type output [@@deriving of_yojson]

  val name : string
  val to_http_request : input -> (Http.Request.t, Error.t) Lwt_result.t
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

let default_of_http_response ~deserialize (response : Http.Response.t) =
  let open Infix.Lwt_result in
  let+ json =
    Http.Response.body response |> Http.Body.to_yojson >|?* fun (`Msg msg) ->
    let* json_str = Http.Body.to_string @@ Http.Response.body response in
    let source = `Serialization (`Raw json_str) in
    Lwt.return @@ Spotify_error.make ~source msg
  in
  match deserialize json with
  | Ok response -> Lwt.return_ok response
  | Error msg ->
      Lwt.return_error
      @@ Spotify_error.make ~source:(`Serialization (`Json json)) msg

let handle_request ?client ~input ~to_http_request ~of_http_response () =
  let+ request = to_http_request input in
  let base_headers =
    Http.Header.add_unless_exists
      (Http.Request.headers request)
      "Content-Type" "application/json"
  in
  let headers' =
    Option.fold ~none:base_headers
      ~some:(fun client' ->
        Http.Header.add_unless_exists base_headers "Authorization"
        @@ Client.get_bearer_token client')
      client
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
        @@ Spotify_error.make
             ~source:(`Http (response_status, request_method, request_uri))
             message
  in
  result

module Make (M : S) = struct
  let request ~client input =
    let open Infix.Lwt_result in
    handle_request ~client ~input ~to_http_request:M.to_http_request
      ~of_http_response:M.of_http_response ()
    >|? fun err ->
    Spotify_error.make ~cause:err ~source:(`Source M.name)
    @@ "Error executing request: " ^ M.name
end

module Make_unauthenticated (M : S) = struct
  let request input =
    let open Infix.Lwt_result in
    handle_request ~input ~to_http_request:M.to_http_request
      ~of_http_response:M.of_http_response ()
    >|? fun err ->
    Spotify_error.make ~cause:err ~source:(`Source M.name)
    @@ "Error executing request: " ^ M.name
end
