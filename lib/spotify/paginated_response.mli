type 'a t [@@deriving show, yojson { strict = false }]

val get_items : 'a t -> 'a list
