type t = Authorization.Access_token.t

let get_bearer_token t = Authorization.Access_token.to_bearer_token t
let make access_token = access_token

type 'a promise = 'a Lwt.t

module HttpRequest = struct
  type t = method_ * headers * endpoint * body

  and method_ =
    [ `GET
    | `POST
    | `PUT
    | `DELETE
    | `HEAD
    | `CONNECT
    | `OPTIONS
    | `TRACE
    | `PATCH ]

  and headers = (string * string) list
  and endpoint = Uri.t
  and body = string option

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

type ('input, 'output, 'error) request =
  (module SpotifyRequest
     with type input = 'input
      and type output = 'output
      and type error = 'error)

let execute_request (type input output error)
    (module M : SpotifyRequest
      with type input = input
       and type output = output
       and type error = error) (t : t) (input : M.input) =
  let method_, headers, endpoint, _body = M.to_http input in
  match method_ with
  | `GET ->
      let headers = ("Authorization", get_bearer_token t) :: headers in
      let%lwt response =
        Http.Client.get ~headers:(Http.Header.of_list headers) endpoint
      in
      Lwt.return (M.of_http response)
  | _ -> failwith "Not implemented"
(* TODO Friday: Continue implementing execute_reqeust *)
