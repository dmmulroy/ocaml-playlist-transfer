open Syntax
open Let

module type S = sig
  type input
  type output

  val to_http : input -> Http.Request.t

  val of_http :
    Http.Request.t * Http.Response.t -> (output, Error.t) Lwt_result.t
end

let execute ({ meth; headers; uri; body } : Http.Request.t) =
  match meth with
  | `GET -> Http.Client.get ~headers uri
  | `POST -> Http.Client.post ~headers ~body uri
  | `PUT -> Http.Client.put ~headers ~body uri
  | `DELETE -> Http.Client.delete ~headers ~body uri

module Make (M : S) = struct
  let request ~(client : Client.t) (input : M.input) :
      (M.output, Error.t) Lwt_result.t =
    let request = M.to_http input in
    let headers' =
      Http.Header.add_list_unless_exists request.headers
        [
          ("Authorization", Client.get_bearer_token client);
          ("Content-Type", "application/json");
        ]
    in
    let request' = { request with headers = headers' } in
    let* response =
      Infix.Lwt.(
        execute request' >|= fun (res, body) ->
        Http.Response.make ~headers:res.headers ~body ~status:res.status ())
    in
    M.of_http (request, response)
end

module Make_unauthenticated (M : S) = struct
  let request (input : M.input) : (M.output, Error.t) Lwt_result.t =
    let request = M.to_http input in
    let headers' =
      Http.Header.add_unless_exists request.headers "Content-Type"
        "application/json"
    in
    let request' = { request with headers = headers' } in
    let* response =
      Infix.Lwt.(
        execute request' >|= fun (res, body) ->
        Http.Response.make ~headers:res.headers ~body ~status:res.status ())
    in
    M.of_http (request, response)
end
