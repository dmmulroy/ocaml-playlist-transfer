type t = string
type error = [ `Song_not_found ]

val error_to_string : error -> string

module Get_song_by_id_input : sig
  type t = string
end

module Get_song_by_id_output : sig
  type nonrec t = t
end

module Get_song_by_id_error : sig
  type t = error

  val to_string : t -> string
end

val get_song_by_id :
  Get_song_by_id_input.t -> (Get_song_by_id_output.t, [> error ]) Lwt_result.t
