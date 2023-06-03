type t
type error = [ `Msg of string ]

(* type grant_type = *)
(*   [ `Authorization of Config.t | `Implicit | `Client_Credentials ] *)

val make : Config.t -> t
val authorization_code_grant : t -> (string, error) result Lwt.t

(* val get_access_token : *)
(*   grant_type:grant_type -> (Access_token.t, error) result Lwt.t *)
