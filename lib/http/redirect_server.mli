type t

val make : redirect_uri:Uri.t -> state:string -> t
val run : t -> unit -> (unit, [ `Msg of string ]) result Lwt.t
val get_code : t -> string Lwt.t
