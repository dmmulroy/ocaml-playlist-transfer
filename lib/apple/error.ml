type t =
  [ `Http_error of int * string
  | `Json_parse_error of string
  | Song.error
  | Authorization.error ]

let to_string = function
  (*
    TODO: Fix Http_error to_string
    ex output: Fatal error: exception Failure("HTTP error 401: ")
   *)
  | #Authorization.error as err -> Authorization.error_to_string err
  | #Song.error as err -> Song.error_to_string err
  | `Http_error (code, msg) -> Printf.sprintf "HTTP error %d: %s" code msg
  | `Json_parse_error msg -> Printf.sprintf "JSON parse error: %s" msg
  | #t -> .
