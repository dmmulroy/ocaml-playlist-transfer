module Jwt = struct
  module Header = Jose.Header
  module Jwt = Jose.Jwt
  module Jwk = Jose.Jwk

  type t = { key : Jwk.priv Jwk.t; jwt : Jwt.t }

  let ( let* ) = Result.bind
  let ( >|= ) r f = Result.map f r
  let six_months_sec = Float.of_int 15777000

  let is_expired t =
    let expiration_result =
      Jwt.check_expiration ~now:(Ptime_clock.now ()) t.jwt
    in
    match expiration_result with Ok _ -> false | Error _ -> true

  let make ?expiration ~private_pem ~key_id ~team_id () =
    let* key = Jwk.of_priv_pem private_pem in
    let kid = ("kid", `String key_id) in
    let header = Header.make_header ~typ:"JWT" ~alg:`ES256 ~extra:[ kid ] key in
    let time = Unix.time () in
    let exp = Option.value ~default:(time +. six_months_sec) expiration in
    let payload =
      Jwt.empty_payload
      |> Jwt.add_claim "iss" (`String team_id)
      |> Jwt.add_claim "iat" (`Float time)
      |> Jwt.add_claim "exp" (`Float exp)
    in
    let* jwt = Jwt.sign ~header ~payload key in
    Ok { key; jwt }

  let to_string t = Jwt.to_string t.jwt

  let validate t =
    Jwt.validate ~jwk:t.key ~now:(Ptime_clock.now ()) t.jwt >|= fun _ -> t
end
