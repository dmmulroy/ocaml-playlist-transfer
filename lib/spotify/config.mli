type t

val make :
  client_id:string -> client_secret:string -> ?redirect_uri:Uri.t -> unit -> t

val set_client_id : t -> string -> t
val set_client_secret : t -> string -> t
val set_redirect_uri : t -> Uri.t -> t
val show : t -> string
