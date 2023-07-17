module type S = sig
  type t [@@deriving show]

  val to_json : t -> Yojson.Safe.t
  val of_json : Yojson.Safe.t -> t
end
