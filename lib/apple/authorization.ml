module Jwt : sig
  type t

  val is_expired : t -> bool
  val make : unit -> unit
  val to_string : t -> string
  val validate : t -> t
end = struct
  type t = Jose.Jwt.t

  let is_expired t =
    let expiration_result =
      Jose.Jwt.check_expiration ~now:(Ptime_clock.now ()) t
    in
    match expiration_result with Ok _ -> false | Error _ -> true

  let make () = () (* TODO *)
  let to_string t = Jose.Jwt.to_string t
  let validate t = t (* TODO *)
end
