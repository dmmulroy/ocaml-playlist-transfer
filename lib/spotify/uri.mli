type t [@@deriving yojson]

val of_string : string -> t
val to_string : t -> string
