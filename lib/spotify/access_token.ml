type t = {
  expiration_time : float;
  refresh_token : string option;
  scopes : Scope.t list option;
  token : string;
}

exception Expired
exception Unauthenticated
exception Unauthorized

let get_expiration_time t = t.expiration_time
let get_refresh_token t = t.refresh_token
let get_scopes t = t.scopes
let get_token t = t.token
let is_expired t = Unix.time () > t.expiration_time

let make ?scopes ?refresh_token ~expiration_time ~token () =
  { token; expiration_time; refresh_token; scopes }

let to_bearer_token t = "Bearer " ^ t.token
