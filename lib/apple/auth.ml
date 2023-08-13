open Syntax
open Let

module Internal_error = struct
  type t =
    [ `Expired
    | `Private_key_error of string
    | `Token_signing_error of string
    | `Unhandled_error of string
    | `Unsupported_kty
    | `Validation_error of string ]

  let to_string = function
    | `Expired -> "The token is expired"
    | `Private_key_error str ->
        "An error occured while parsing private key PEM: " ^ str
    | `Token_signing_error str ->
        "An error occurred while signing the token: " ^ str
    | `Unsupported_kty -> "The private key is not an ES256 key"
    | `Unhandled_error str -> "An unhandled error occurred: " ^ str
    | `Validation_error str ->
        "An error occurred while validating the token: " ^ str
    | #t -> .
    | _ -> "An unhandled error occurred"

  let to_error ?(map_msg = fun str -> `Unhandled_error str) err =
    let message =
      (match err with `Msg str -> map_msg str | _ as err' -> err')
      |> to_string
    in
    Error.make ~domain:`Apple ~source:`Auth message
end

module Jwt = struct
  module Header = Jose.Header
  module Jwt = Jose.Jwt
  module Jwk = Jose.Jwk

  type t = { key : Jwk.priv Jwk.t; jwt : Jwt.t }

  let six_months_sec = 15777000

  let is_expired t =
    let expiration_result =
      Jwt.check_expiration ~now:(Ptime_clock.now ()) t.jwt
    in
    match expiration_result with Ok _ -> false | Error _ -> true

  let make ?expiration ~private_pem ~key_id ~team_id () =
    let open Infix.Result in
    let@ key =
      Jwk.of_priv_pem private_pem
      >|? Internal_error.to_error ~map_msg:(fun msg -> `Private_key_error msg)
    in
    let kid = ("kid", `String key_id) in
    let header = Header.make_header ~typ:"JWT" ~alg:`ES256 ~extra:[ kid ] key in
    let time = Int.of_float @@ Unix.time () in
    let exp = Option.value ~default:(time + six_months_sec) expiration in
    let payload =
      Jwt.empty_payload
      |> Jwt.add_claim "iss" (`String team_id)
      |> Jwt.add_claim "iat" (`Int time)
      |> Jwt.add_claim "exp" (`Int exp)
    in
    let@ jwt =
      Jwt.sign ~header ~payload key
      >|? Internal_error.to_error ~map_msg:(fun msg -> `Token_signing_error msg)
    in
    Ok { key; jwt }

  let to_bearer_token t = "Bearer " ^ Jwt.to_string t.jwt
  let to_string t = Jwt.to_string t.jwt

  let validate t =
    let open Infix.Result in
    let@ validated_jwt =
      Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt
      >|? Internal_error.to_error ~map_msg:(fun msg -> `Validation_error msg)
    in
    Ok { t with jwt = validated_jwt }
end

module Test_auth_input = struct
  type t = Jwt.t
end

module Test_auth_output = struct
  type t = unit
end

module Test_auth = Apple_request.Make_unauthenticated (struct
  type input = Test_auth_input.t
  type output = Test_auth_output.t

  let to_http jwt =
    let meth = `GET in
    let headers =
      Http.Header.add Http.Header.empty "Auth" (Jwt.to_bearer_token jwt)
    in
    let uri = Uri.of_string "https://api.music.apple.com/v1/test" in
    let body = Http.Body.empty in
    Http.Request.make ~meth ~headers ~uri ~body ()

  let of_http = function
    | _, response when Http.Response.is_success response -> Lwt.return_ok ()
    | request, response ->
        Infix.Lwt.(
          Error.of_http ~domain:`Apple (request, response) >>= Lwt.return_error)
end)

let test_auth = Test_auth.request
