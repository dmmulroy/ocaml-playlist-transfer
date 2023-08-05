type t = [ Song.error | `Json_parse_error ]

let to_string (err : [< t ]) =
  match err with
  | #Song.error as err -> Song.error_to_string err
  (* | #Apple_request.error as err -> Apple_request.error_to_string err *)
  | `Json_parse_error -> "JSON parse error"
  | #t -> .

module type S = sig
  type t

  val to_string : t -> string
end

module Make (M : S) : S with type t = M.t = struct
  include M

  let to_string = M.to_string
end
