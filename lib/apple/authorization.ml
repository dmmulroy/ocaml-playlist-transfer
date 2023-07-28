module Jwt = struct
  type t = Jose.Jwt.t

  let is_expired _t = false (* TODO *)
  let make () = () (* TODO *)
  let to_string t = Jose.Jwt.to_string t (* TODO *)
  let validate t = t (* TODO *)
end
