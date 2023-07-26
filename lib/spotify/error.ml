type t = [ Authorization.error | Common.error | `Unknown_error ]

let to_string (err : [< t ]) =
  match err with
  | #Common.error as err -> Common.error_to_string err
  | #Authorization.error as err -> Authorization.error_to_string err
  | `Unknown_error -> "Unknown error"
  | #t -> .
