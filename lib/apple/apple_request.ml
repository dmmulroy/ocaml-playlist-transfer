open Syntax
open Let

type 'a apple_error = [ `Apple_error of 'a ]

module type S = sig
  type input
  type output
  type error

  val to_http :
    input -> Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http : Http.Response.t * Http.Body.t -> (output, error) Lwt_result.t
end

let execute ~headers ~body ~endpoint ~method' =
  match method' with
  | `GET -> Http.Client.get ~headers endpoint
  | `POST -> Http.Client.post ~headers ~body endpoint
  | `PUT -> Http.Client.put ~headers ~body endpoint
  | `DELETE -> Http.Client.delete ~headers ~body endpoint
  | _ -> failwith "Not implemented"

let wrap_error error = `Apple_error error

module Make_unauthenticated (M : S) = struct
  let request (input : M.input) : (M.output, M.error apple_error) Lwt_result.t =
    let method', headers', endpoint, body = M.to_http input in
    let headers =
      Http.Header.add_unless_exists headers' "Content-Type" "application/json"
    in
    let* response = execute ~headers ~body ~endpoint ~method' in
    Infix.Lwt.(M.of_http response >|? wrap_error)
end
