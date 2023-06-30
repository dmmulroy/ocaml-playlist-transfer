type t = Authorization.Access_token.t

let get_bearer_token t = Authorization.Access_token.to_bearer_token t
let make access_token = access_token

module type SpotifyRequest = sig
  type input
  type output
  type error

  val to_http :
    input -> Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http : Http.Response.t * Http.Body.t -> (output, error) result
end

module MakeRequestExecutor (M : SpotifyRequest) = struct
  open Async

  let execute ~(client : t) (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers, endpoint, body = M.to_http input in
    match method' with
    | `GET ->
        let headers =
          Http.Header.add headers "Authorization" @@ get_bearer_token client
        in
        let%lwt response = Http.Client.get ~headers endpoint in
        Lwt.return (M.of_http response)
    | `POST ->
        let headers =
          Http.Header.add headers "Authorization" @@ get_bearer_token client
        in
        let%lwt response = Http.Client.post ~headers ~body endpoint in
        Lwt.return (M.of_http response)
    | _ -> failwith "Not implemented"
end
