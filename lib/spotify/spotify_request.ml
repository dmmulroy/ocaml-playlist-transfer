open Async

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

module Make (M : S) = struct
  let request ~(client : Client.t) ?options (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers, endpoint, body =
      match options with
      | Some options -> M.to_http ~options input
      | None -> M.to_http input
    in
    let headers =
      Http.Header.add_list headers
        [
          ("Authorization", Client.get_bearer_token client);
          ("Content-Type", "application/json");
        ]
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

  let unauthenticated_request ?options (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers', endpoint, body =
      match options with
      | Some options -> M.to_http ~options input
      | None -> M.to_http input
    in
    let headers =
      Http.Header.add_unless_exists headers' "Content-Type" "application/json"
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
