type t = {
  expiration_time : float;
  grant_type : [ `Authorization_code | `Client_credentials ];
  refresh_token : string option;
  scopes : Scope.t list option;
  token : string;
}
[@@deriving yojson]

let get_expiration_time t = t.expiration_time
let get_grant_type t = t.grant_type
let get_refresh_token t = t.refresh_token
let get_scopes t = t.scopes
let get_token t = t.token
let is_expired t = Unix.time () > t.expiration_time

let make ?scopes ?refresh_token ~expiration_time ~grant_type ~token () =
  { token; grant_type; expiration_time; refresh_token; scopes }

let set_expiration_time t expiration_time = { t with expiration_time }
