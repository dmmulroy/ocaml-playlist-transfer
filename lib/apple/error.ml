module type S = sig
  type t = private [> ]

  val to_string : t -> string
end

module Make (M : S) : S with type t = M.t = struct
  include M

  let to_string = M.to_string
end

module Http_error = Make (struct
  type t = [ `Http_error of int * string ]

  let to_string = function
    | `Http_error (code, msg) -> Printf.sprintf "HTTP error %d: %s" code msg
end)

module Json_parse_error = Make (struct
  type t = [ `Json_parse_error of string ]

  let to_string = function
    | `Json_parse_error msg -> Printf.sprintf "JSON parse error: %s" msg
end)

module Song_error = Make (struct
  type t = [ `Song_not_found | Http_error.t ]

  let to_string = function
    | `Song_not_found -> "Song not found"
    | #Http_error.t as err -> Http_error.to_string err
end)

module Authorization_error = Make (struct
  type t = Http_error.t

  let to_string = function #Http_error.t as err -> Http_error.to_string err
end)

type t =
  [ Http_error.t | Song_error.t | Authorization_error.t | Json_parse_error.t ]

let to_string (err : [< t ]) =
  match err with
  | #Http_error.t as err -> Http_error.to_string err
  (* | #Authorization_error.t as err -> Authorization_error.to_string err *)
  | #Json_parse_error.t as err -> Json_parse_error.to_string err
  | #Song_error.t as err -> Song_error.to_string err
  | #t -> .
