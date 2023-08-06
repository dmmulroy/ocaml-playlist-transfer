type t =
  [ `Http_error of int * string | `Json_parse_error of string | `Song_not_found ]

let to_string (err : [< t ]) =
  match err with
  | `Http_error (code, msg) -> Printf.sprintf "HTTP error %d: %s" code msg
  | `Json_parse_error msg -> Printf.sprintf "JSON parse error: %s" msg
  | `Song_not_found -> "Song not found"
  | #t -> .
