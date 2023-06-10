type t = Authorization.Access_token.t

let get_bearer_token t = Authorization.Access_token.to_bearer_token t
let make access_token = access_token
