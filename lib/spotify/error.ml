type t =
  (* Common errors *)
  [ `Json_parse_error of string
  | `Http_error of int * string
  | Authorization.error ]

let to_string = function
  | `Json_parse_error msg -> "Error parsing JSON response: " ^ msg
  | `Http_error (status_code, msg) ->
      Printf.sprintf "Request error: [%d]: %s" status_code msg
  | #Authorization.error as err -> Authorization.error_to_string err
  | #t -> .
