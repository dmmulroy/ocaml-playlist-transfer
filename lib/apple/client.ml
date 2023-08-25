type t = { jwt : Jwt.t; music_user_token : string }

let get_bearer_token t = Jwt.to_string t.jwt
let jwt t = t.jwt
let music_user_token t = t.music_user_token
let make ~jwt ~music_user_token = { jwt; music_user_token }
