type t = { access_token : string }

val init : client_id:string -> client_secret:string -> t Lwt.t
