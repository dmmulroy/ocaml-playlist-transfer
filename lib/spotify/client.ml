(* TODO Sunday: update type t to be more than an alias *)
type t = { access_token : Access_token.t option }

let get_access_token t =
  match t.access_token with
  | Some token -> Ok (Access_token.to_bearer_token token)
  | None -> Error `Unauthenticated

let init ?access_token () = { access_token }
let make access_token = { access_token }
let set_access_token _t access_token = { access_token }
