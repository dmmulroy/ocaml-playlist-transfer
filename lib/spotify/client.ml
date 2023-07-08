(* TODO Sunday: update type t to be more than an alias *)
type t = Access_token.t

let get_bearer_token t = Access_token.to_bearer_token t
let init ?access_token () = access_token
let make access_token = access_token
let set_access_token _t access_token = access_token
