type t = { developer_token : Jwt.t; music_user_token : string }

let get_bearer_token t = Jwt.to_string t.developer_token
let developer_token t = t.developer_token
let music_user_token t = t.music_user_token

let make ~developer_token ~music_user_token =
  { developer_token; music_user_token }
