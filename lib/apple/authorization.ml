open Syntax
open Let

type error =
  [ `Expired
  | `Private_key_error of string
  | `Token_signing_error of string
  | `Unsupported_kty
  | `Validation_error of string ]

let error_to_string = function
  | `Expired -> "The token is expired"
  | `Private_key_error str ->
      "An error occured while parsing private key PEM: " ^ str
  | `Token_signing_error str ->
      "An error occurred while signing the token: " ^ str
  | `Unsupported_kty -> "The private key is not an ES256 key"
  | `Validation_error str ->
      "An error occurred while validating the token: " ^ str

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
      Jwk.of_priv_pem private_pem >|? fun err ->
      match err with
      | `Msg str -> `Private_key_error str
      | `Unsupported_kty as err -> err
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
      Jwt.sign ~header ~payload key >|? fun (`Msg str) ->
      `Token_signing_error str
    in
    Ok { key; jwt }

  let to_bearer_token t = "Bearer " ^ Jwt.to_string t.jwt
  let to_string t = Jwt.to_string t.jwt

  let validate t =
    let open Infix.Result in
    let@ validated_jwt =
      Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt >|? fun err ->
      match err with
      | `Msg str -> `Validation_error str
      | `Expired -> `Expired
      | `Invalid_signature -> `Invalid_signature
    in
    Ok { t with jwt = validated_jwt }
end

module Test_authorization_input = struct
  type t = Jwt.t
end

module Test_authorization_output = struct
  type t = unit
end

module Test_authorization = Apple_request.Make_unauthenticated (struct
  type input = Test_authorization_input.t
  type output = Test_authorization_output.t
  type error = [ `Http_error of int * string ]

  let to_http jwt =
    let headers =
      Http.Header.add Http.Header.empty "Authorization"
        (Jwt.to_bearer_token jwt)
    in
    ( `GET,
      headers,
      Uri.of_string "https://api.music.apple.com/v1/test",
      Http.Body.empty )

  let of_http = function
    | res, _ when Http.Response.is_success res -> Lwt.return_ok ()
    | res, body ->
        let* json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error
          (`Http_error (Http.Code.code_of_status status_code, json))
end)

let test_authorization = Test_authorization.request
