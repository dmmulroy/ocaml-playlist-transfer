type _ storage = Int : int storage | String : string storage

module Storage : sig
  module type S = sig
    type s

    val storage : s storage
  end

  module IntStorage : sig
    type s = int

    val storage : s storage
  end

  module StringStorage : sig
    type s = string

    val storage : s storage
  end
end

module type S = sig
  include Model.S
  include Storage.S

  val storage : s storage
  val encode : t -> (s, string) result
  val decode : s -> (t, string) result
end

module Make (M : S) : sig
  type t = M.t

  val petrol_type : t Petrol.Type.t
end
