type t =
  [ `Json_parse_error of string
  | `No_refresh_token
  | `Invalid_grant_type
  | `Http_error of int * string ]

let to_string (err : [< t ]) =
  match err with
  | `Json_parse_error msg -> "Error parsing JSON response: " ^ msg
  | `Http_error (status_code, msg) ->
      Printf.sprintf "Request error: [%d]: %s" status_code msg
  | `No_refresh_token -> "No refresh token"
  | `Invalid_grant_type -> "Invalid grant type"
  | #t -> .
