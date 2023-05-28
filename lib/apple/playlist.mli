type t

val get_id : t -> string
val get_name : t -> string option
val get_description : t -> string option
val get_tracks : t -> Song.t list option
val is_public : t -> bool option
val get_date_added : t -> string option
