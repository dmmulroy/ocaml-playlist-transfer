type meta = {
  expiration_time : int;
  grant_type : [ `Authorization_code | `Client_credentials ];
  refresh_token : string option;
  scopes : Scope.t list option;
}
[@@deriving yojson]

type t = { token : string; meta : meta option } [@@deriving yojson]

let get_expiration_time access_token =
  match access_token.meta with
  | Some meta -> Some meta.expiration_time
  | None -> None

let get_grant_type access_token =
  match access_token.meta with
  | Some meta -> Some meta.grant_type
  | None -> None

let get_refresh_token access_token =
  match access_token.meta with Some meta -> meta.refresh_token | None -> None

let get_scopes access_token =
  match access_token.meta with Some meta -> meta.scopes | None -> None

let of_string str = { token = str; meta = None }
let to_string access_token = access_token.token

let is_expired access_token =
  match access_token.meta with
  | Some meta ->
      meta.expiration_time < (Unix.time () |> Int.of_float) |> Option.some
  | None -> None

let make ?scopes ?refresh_token ~expiration_time ~grant_type ~token () =
  let meta = { expiration_time; grant_type; refresh_token; scopes } in
  { token; meta = Some meta }

let set_expiration_time access_token expiration_time =
  match access_token.meta with
  | Some meta -> { access_token with meta = Some { meta with expiration_time } }
  | None -> access_token
