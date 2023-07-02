module type S = sig
  open Async

  type input
  type output
  type error

  val to_http :
    input -> Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http :
    Http.Response.t * Http.Body.t -> (output, error) result Promise.t
end

module Make (M : S) = struct
  open Async

  let request ~(client : Client.t) (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers, endpoint, body = M.to_http input in
    let headers =
      Http.Header.add headers "Authorization" @@ Client.get_bearer_token client
    in
    let%lwt response =
      match method' with
      | `GET -> Http.Client.get ~headers endpoint
      | `POST -> Http.Client.post ~headers ~body endpoint
      | `PUT -> Http.Client.put ~headers ~body endpoint
      | `DELETE -> Http.Client.delete ~headers ~body endpoint
      | _ -> failwith "Not implemented"
    in
    M.of_http response
end
