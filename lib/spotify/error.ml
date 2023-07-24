type t =
  [ Authorization.error | Common.error | Spotify_request.error | `Unknown_error ]

let to_string (err : [< t ]) =
  match err with
  | #Common.error as err -> Common.error_to_string err
  | #Spotify_request.error as err -> Spotify_request.error_to_string err
  | #Authorization.error as err -> Authorization.error_to_string err
  | `Unknown_error -> "Unknown error"
  | #t -> .
