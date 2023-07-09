type t = { access_token : Access_token.t }

let get_bearer_token t = Access_token.to_bearer_token t.access_token
let make access_token = { access_token }
let set_access_token _t access_token = { access_token }
