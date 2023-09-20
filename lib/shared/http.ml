open Syntax
open Let
include Cohttp
include Cohttp_lwt
include Cohttp_lwt_unix

module Body = struct
  include Body

  let to_yojson body =
    let* body' = Body.to_string body in
    let| json =
      try Ok (Yojson.Safe.from_string body')
      with Yojson.Json_error msg -> Error msg
    in
    Lwt.return_ok json

  let of_yojson json =
    try Yojson.Safe.to_string json |> Body.of_string |> Result.ok
    with Yojson.Json_error msg -> Error msg
end

module Code = struct
  include Code

  let reason_phrase_of_status_code status_code =
    Code.code_of_status status_code |> Code.reason_phrase_of_code

  let pp_status_code ppf code =
    Format.fprintf ppf "%d" @@ Code.code_of_status code
end

module Header = struct
  include Header

  let empty = Header.init ()

  let add_unless_exists headers new_headers =
    List.fold_left
      (fun headers' (key, value) -> Header.add_unless_exists headers' key value)
      headers (to_list new_headers)
end

module Uri = struct
  include Uri

  let to_yojson uri = `String (Uri.to_string uri)

  let of_yojson = function
    | `String s -> Ok (Uri.of_string s)
    | _ -> Error "Error parsing Uri.t with yojson"
end

module Client = struct
  include Client

  let get ?headers uri = get ?headers uri
  let post ?headers ?body uri = post ?headers ?body uri
  let put ?headers ?body uri = put ?headers ?body uri
  let delete ?headers ?body uri = delete ?headers ?body uri
end

module Cohttp_request = struct
  include Cohttp_lwt_unix.Request

  let uri request = uri request
end

module Request = struct
  type t = {
    body : Body.t;
    headers : Header.t;
    meth : [ `GET | `POST | `PUT | `DELETE ];
    uri : Uri.t;
  }

  let body { body; _ } = body
  let headers { headers; _ } = headers
  let meth { meth; _ } = meth
  let uri { uri; _ } = uri

  let set_headers request headers' =
    { request with headers = Header.add_unless_exists request.headers headers' }

  let set_body request body' = { request with body = body' }
  let set_meth request meth' = { request with meth = meth' }
  let set_uri request uri' = { request with uri = uri' }

  let make ?(headers = Header.empty) ?(body = Body.empty) ~meth ~uri () =
    { headers; body; meth; uri }
end

module Response = struct
  type t = { headers : Header.t; status : Code.status_code; body : Body.t }

  let body { body; _ } = body
  let headers { headers; _ } = headers
  let status { status; _ } = status
  let is_success res = res |> status |> Code.code_of_status |> Code.is_success
  let is_error res = res |> status |> Code.code_of_status |> Code.is_error

  let make ?(headers = Header.empty) ?(body = Body.empty) ~status () =
    { headers; status; body }
end
