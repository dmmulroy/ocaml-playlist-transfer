type t = { jwt : Auth.Jwt.t; music_user_token : string }

let get_bearer_token t = Auth.Jwt.to_bearer_token t.jwt
let jwt t = t.jwt
let music_user_token t = t.music_user_token
let make ~jwt ~music_user_token = { jwt; music_user_token }
