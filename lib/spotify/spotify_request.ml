open Async

type error = [ `Request_error of Http.Code.status_code * string ]

let error_to_string = function
  | `Request_error (status_code, msg) ->
      Printf.sprintf "Request error: [%d]: %s"
        (Http.Code.code_of_status status_code)
        msg

module type S = sig
  type input
  type options
  type output
  type error

  val to_http :
    ?options:options ->
    input ->
    Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http :
    Http.Response.t * Http.Body.t -> (output, error) result Promise.t
end

let execute_request ~headers ~body ~endpoint ~method' =
  match method' with
  | `GET -> Http.Client.get ~headers endpoint
  | `POST -> Http.Client.post ~headers ~body endpoint
  | `PUT -> Http.Client.put ~headers ~body endpoint
  | `DELETE -> Http.Client.delete ~headers ~body endpoint
  | _ -> failwith "Not implemented"

module Make (M : S) = struct
  let request ~(client : Client.t) ?(options : M.options option)
      (input : M.input) : (M.output, M.error) result Promise.t =
    let method', headers', endpoint, body = M.to_http ?options input in
    let headers =
      Http.Header.add_list_unless_exists headers'
        [
          ("Authorization", Client.get_bearer_token client);
          ("Content-Type", "application/json");
        ]
    in
    let%lwt response = execute_request ~headers ~body ~endpoint ~method' in
    M.of_http response

  let unauthenticated_request ?(options : M.options option) (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers', endpoint, body = M.to_http ?options input in
    let headers =
      Http.Header.add_unless_exists headers' "Content-Type" "application/json"
    in
    let%lwt response = execute_request ~headers ~body ~endpoint ~method' in
    M.of_http response
end
