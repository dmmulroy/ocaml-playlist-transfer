type t = Authorization.Access_token.t

let get_bearer_token t = Authorization.Access_token.to_bearer_token t
let make access_token = access_token

type 'a promise = 'a Lwt.t

module HttpRequest = struct
  type t = method' * headers * endpoint * body
  and method' = [ `GET | `POST ]
  and headers = Http.Header.t
  and endpoint = Uri.t
  and body = Http.Body.t

  (* val method_to_string : [< method_ ] -> string *)
  (* val method_of_string : string -> method_ *)
end

module HttpResponse = struct
  type t = Http.Response.t * Http.Body.t
end

module type SpotifyRequest = sig
  type input
  type output
  type error

  val to_http : input -> HttpRequest.t
  val of_http : HttpResponse.t -> (output, error) result
end

module MakeRequestExecutor (M : SpotifyRequest) = struct
  let execute ~(client : t) (input : M.input) :
      (M.output, M.error) result promise =
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
end
