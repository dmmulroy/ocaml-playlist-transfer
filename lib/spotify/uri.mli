type t

val of_string : string -> (t, [ `Msg of string ]) result
val to_string : t -> string
