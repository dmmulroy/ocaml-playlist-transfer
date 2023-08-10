open Syntax
open Let

type internal_error =
  [ `Expired
  | `Private_key_error of string
  | `Token_signing_error of string
  | `Unsupported_kty
  | `Validation_error of string ]

(* TODO: Improve these error messags for new Error.t type *)
let internal_error_to_string = function
  | `Expired -> "The token is expired"
  | `Private_key_error str ->
      "An error occured while parsing private key PEM: " ^ str
  | `Token_signing_error str ->
      "An error occurred while signing the token: " ^ str
  | `Unsupported_kty -> "The private key is not an ES256 key"
  | `Validation_error str ->
      "An error occurred while validating the token: " ^ str

let internal_error_to_error err =
  Error.make ~source:`Authorization ~message:(internal_error_to_string err) ()

let internal_error_identity = function
  | `Expired -> `Expired
  | `Private_key_error str -> `Private_key_error str
  | `Token_signing_error str -> `Token_signing_error str
  | `Unsupported_kty -> `Unsupported_kty
  | `Validation_error str -> `Validation_error str
  | _ -> assert false

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
      >|? (fun err ->
            match err with
            | `Msg str -> `Private_key_error str
            | _ as err -> internal_error_identity err)
      >|? internal_error_to_error
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
      >|? (fun (`Msg str) -> `Token_signing_error str)
      >|? internal_error_to_error
    in
    Ok { key; jwt }

  let to_bearer_token t = "Bearer " ^ Jwt.to_string t.jwt
  let to_string t = Jwt.to_string t.jwt

  let validate t =
    let open Infix.Result in
    let@ validated_jwt =
      Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt
      >|? (fun err ->
            match err with
            | `Msg str -> `Validation_error str
            | _ as err -> internal_error_identity err)
      >|? internal_error_to_error
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
    | res, body -> Infix.Lwt.(Error.of_http (res, body) >>= Lwt.return_error)
end)

let test_authorization = Test_authorization.request
