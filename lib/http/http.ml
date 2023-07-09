include Cohttp
include Cohttp_lwt
include Cohttp_lwt_unix
module Redirect_server = Redirect_server

module Body = struct
  include Body

  let to_yojson body =
    let%lwt body = Body.to_string body in
    let json = Yojson.Safe.from_string body in
    Lwt.return json

  let of_yojson json = Body.of_string @@ Yojson.Safe.to_string json
end

module Header = struct
  include Header

  let empty = Header.init ()
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
