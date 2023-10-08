open Shared

module Test_auth_input = struct
  type t = unit
end

module Test_auth_output = struct
  type t = unit [@@deriving yojson]
end

module Test_auth = struct
  type input = Test_auth_input.t
  type output = Test_auth_output.t

  let name = "Test_auth"

  let to_http_request input =
    let meth = `GET in
    let headers = Http.Header.empty in
    let uri = Http.Uri.of_string "https://api.music.apple.com/v1/test" in
    let body = Http.Body.empty in
    Lwt.return_ok @@ Http.Request.make ~meth ~headers ~uri ~body input

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:(fun _ -> Ok ())
end

let test_auth ~client () =
  let module Request = Apple_rest_client.Make (Test_auth) in
  Request.request ~client () |> Lwt_result.map Apple_rest_client.Response.make
