type t = { jwt : Auth.Jwt.t; music_user_token : string }

let make ~jwt ~music_user_token = { jwt; music_user_token }
