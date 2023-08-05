type t = string

module Get_song_by_id_input : sig
  type t = string
end

module Get_song_by_id_output : sig
  type nonrec t = t
end

val get_song_by_id :
  Get_song_by_id_input.t ->
  (Get_song_by_id_output.t, Error.Song_error.t) Lwt_result.t
