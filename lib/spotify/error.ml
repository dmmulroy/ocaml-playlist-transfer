type error = [ Authorization.error | `Unknown_error ]

let to_string (err : [< error ]) =
  match err with
  | `Request_error (status_code, msg) ->
      Printf.sprintf "Request error: %d %s"
        (Http.Code.code_of_status @@ status_code)
        msg
  | `Json_parse_error -> Printf.sprintf "Error parsing JSON response"
  | `Unknown_error -> Printf.sprintf "Unknown error"
