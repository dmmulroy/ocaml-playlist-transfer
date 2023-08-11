open Syntax
open Let
include Cohttp
include Cohttp_lwt
include Cohttp_lwt_unix
module Redirect_server = Redirect_server

module Body = struct
  include Body

  let to_yojson body =
    let* body' = Body.to_string body in
    let| json =
      try Ok (Yojson.Safe.from_string body')
      with Yojson.Json_error msg -> Error (`Json_error msg)
    in
    Lwt.return_ok json

  let of_yojson json = Body.of_string @@ Yojson.Safe.to_string json
end

module Header = struct
  include Header

  let empty = Header.init ()

  let add_list_unless_exists headers new_headers =
    List.fold_left
      (fun headers' (key, value) -> Header.add_unless_exists headers' key value)
      headers new_headers
end

module Response = struct
  include Response

  let is_success res =
    res |> Response.status |> Code.code_of_status |> Code.is_success
end

module Uri = struct
  include Uri

  let to_yojson uri = `String (Uri.to_string uri)

  let of_yojson = function
    | `String s -> Ok (Uri.of_string s)
    | _ -> Error "Error parsing Uri.t with yojson"
end

module Api_request = struct
  module type S = sig
    type input
    type output
    type error

    val to_http : input -> Code.meth * Header.t * Uri.t * Body.t
    val of_http : Response.t * Body.t -> (output, error) Lwt_result.t
  end

  let execute ~headers ~body ~endpoint ~method' =
    match method' with
    | `GET -> Client.get ~headers endpoint
    | `POST -> Client.post ~headers ~body endpoint
    | `PUT -> Client.put ~headers ~body endpoint
    | `DELETE -> Client.delete ~headers ~body endpoint
    | _ -> failwith "Not implemented"
end
