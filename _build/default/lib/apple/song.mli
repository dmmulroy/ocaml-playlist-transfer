type t

val get_id : t -> string
val get_name : t -> string option
val get_album_name : t -> string option
val get_artist_name : t -> string option
val get_duration_ms : t -> int option
val get_genre_names : t -> string list option
val get_track_number : t -> int option
val get_release_date : t -> string option
