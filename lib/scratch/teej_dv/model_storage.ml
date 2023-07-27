type _ storage = Int : int storage | String : string storage

let to_caqti_storage : type a. a storage -> a Caqti_type.t = function
  | Int -> Caqti_type.int
  | String -> Caqti_type.string

module Storage = struct
  module type S = sig
    type s

    val storage : s storage
  end

  module IntStorage : S with type s = int = struct
    type s = int

    let storage = Int
  end

  module StringStorage : S with type s = string = struct
    type s = string

    let storage = String
  end
end

module type S = sig
  include Model.S
  include Storage.S

  val storage : s storage
  val encode : t -> (s, string) result
  val decode : s -> (t, string) result
end

module Make (M : S) = struct
  type t = M.t

  let ty =
    Caqti_type.custom ~encode:M.encode ~decode:M.decode
      (to_caqti_storage M.storage)

  let petrol_type = Petrol.Type.custom ~ty ~repr:M.name
end
