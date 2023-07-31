module Jwt = struct
  module Header = Jose.Header
  module Jwt = Jose.Jwt
  module Jwk = Jose.Jwk

  type t = { key : Jwk.priv Jwk.t; jwt : Jwt.t }

  let ( let* ) = Result.bind
  let ( >|= ) r f = Result.map f r
  let six_months_sec = 15777000

  let is_expired t =
    let expiration_result =
      Jwt.check_expiration ~now:(Ptime_clock.now ()) t.jwt
    in
    match expiration_result with Ok _ -> false | Error _ -> true

  let make ?expiration ~private_pem ~key_id ~team_id () =
    let* key = Jwk.of_priv_pem private_pem in
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
    let* jwt = Jwt.sign ~header ~payload key in
    Ok { key; jwt }

  let to_bearer_token t = "Bearer " ^ Jwt.to_string t.jwt
  let to_string t = Jwt.to_string t.jwt

  let validate t =
    Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt >|= fun _ -> t
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
  type error = Http.Api_request.error

  let to_http jwt =
    let headers =
      Http.Header.add Http.Header.empty "Authorization" (Jwt.to_string jwt)
    in
    ( `GET,
      headers,
      Uri.of_string "https://api.music.apple.com/v1/test",
      Http.Body.empty )

  let of_http = function
    | res, _ when Http.Response.is_success res -> Lwt.return_ok ()
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Request_error (status_code, json))
end)

let test_authorization = Test_authorization.request
