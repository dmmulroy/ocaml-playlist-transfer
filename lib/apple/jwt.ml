open Shared
open Syntax
open Let
module Header = Jose.Header
module Jwt = Jose.Jwt
module Jwk = Jose.Jwk

module Internal_error = struct
  type t =
    [ `Expired
    | `Invalid_signature
    | `Not_json
    | `Not_supported
    | `Private_key_error of string
    | `Token_signing_error of string
    | `Unhandled_error of string
    | `Unsupported_kty
    | `Validation_error of string ]

  let to_string = function
    | `Expired -> "The token is expired"
    | `Invalid_signature -> "The token signature is invalid"
    | `Not_json -> "The token is not valid JSON"
    | `Not_supported -> "The token is not supported"
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

  let private_key_error str = `Private_key_error str
  let token_signing_error str = `Token_signing_error str
  let validation_error str = `Validation_error str

  let to_apple_error ?(map_msg = fun str -> `Unhandled_error str)
      (err : [< t | `Msg of string ]) =
    (match err with `Msg str -> map_msg str | _ as err' -> err')
    |> to_string
    |> Apple_error.make ~source:`Auth
end

type t = { key : Jwk.priv Jwk.t; jwt : Jwt.t }

let six_months_sec = 15777000

let is_expired t =
  t.jwt
  |> Jwt.check_expiration ~now:(Ptime_clock.now ())
  |> Result.map @@ Fun.const false
  |> Result.value ~default:true

let make ?expiration ~private_pem ~key_id ~team_id () =
  let open Infix.Result in
  let@ key =
    Jwk.of_priv_pem private_pem
    >|? Internal_error.to_apple_error ~map_msg:Internal_error.private_key_error
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
    >|? Internal_error.to_apple_error
          ~map_msg:Internal_error.token_signing_error
  in
  Ok { key; jwt }

let of_string ~private_pem jwt_str =
  let open Infix.Result in
  let@ key =
    Jwk.of_priv_pem private_pem
    >|? Internal_error.to_apple_error ~map_msg:Internal_error.private_key_error
  in
  let@ jwt =
    Jwt.of_string ~jwk:key ~now:(Ptime_clock.now ()) jwt_str
    >|? Internal_error.to_apple_error
  in
  Ok { key; jwt }

let to_string t = Jwt.to_string t.jwt

let validate t =
  let open Infix.Result in
  let@ validated_jwt =
    Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt
    >|? Internal_error.to_apple_error ~map_msg:Internal_error.validation_error
  in
  Ok { t with jwt = validated_jwt }
