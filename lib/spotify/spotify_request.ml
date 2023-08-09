module type S = sig
  type input
  type output
  type error = private [> `Http_error of int * string ]

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

module Make (M : S) = struct
  let request ~(client : Client.t) (input : M.input) :
      (M.output, M.error) Lwt_result.t =
    let method', headers', endpoint, body = M.to_http input in
    let headers =
      Http.Header.add_list_unless_exists headers'
        [
          ("Authorization", Client.get_bearer_token client);
          ("Content-Type", "application/json");
        ]
    in
    let%lwt response = execute ~headers ~body ~endpoint ~method' in
    M.of_http response
end

module Make_unauthenticated (M : S) = struct
  let request (input : M.input) : (M.output, M.error) Lwt_result.t =
    let method', headers', endpoint, body = M.to_http input in
    let headers =
      Http.Header.add_unless_exists headers' "Content-Type" "application/json"
    in
    let%lwt response = execute ~headers ~body ~endpoint ~method' in
    M.of_http response
end
