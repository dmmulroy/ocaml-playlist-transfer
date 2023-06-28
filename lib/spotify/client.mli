type t

val get_bearer_token : t -> string
val make : Authorization.Access_token.t -> t

(*
    TODO Thursday: Migrate to from cohttp_lwt_unix to Dream.hyper and design the
    client to execute api calls
*)
