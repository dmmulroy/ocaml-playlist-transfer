type 'a t [@@deriving show, yojson]

val get_items : 'a t -> 'a list
