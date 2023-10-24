type t = { access_token : Access_token.t }

let get_access_token { access_token; _ } = access_token
let get_bearer_token { access_token; _ } = Access_token.get_token access_token
let make ~access_token = { access_token }
let set_access_token _t access_token = { access_token }
