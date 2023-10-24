type t = { access_token : Access_token.t }

let get_access_token { access_token; _ } = access_token
let get_bearer_token { access_token; _ } = Access_token.to_string access_token

let make
    ~(access_token : [ `Access_token of Access_token.t | `String of string ]) =
  match access_token with
  | `Access_token access_token -> { access_token }
  | `String access_token ->
      { access_token = Access_token.of_string access_token }

let set_access_token _client access_token =
  let access_token = Access_token.of_string access_token in
  { access_token }
