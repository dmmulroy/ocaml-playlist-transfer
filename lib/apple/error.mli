type t = {
  cause : t option;
  code : Http.Code.status_code option;
  source : [ `Auth | `Http | `None | `Resource of Resource.t ];
  field : string option;
  message : string;
  raw : [ `Json of Yojson.Safe.t | `None | `Raw of string ];
  timestamp : Ptime.t;
}

val make :
  ?cause:t ->
  ?code:Http.Code.status_code ->
  ?field:string ->
  ?raw:[ `Json of Yojson.Safe.t | `None | `Raw of string ] ->
  source:[ `Auth | `Http | `None | `Resource of Resource.t ] ->
  message:string ->
  unit ->
  t

val of_http : ?cause:t -> Http.Response.t * Http.Body.t -> t Lwt.t
val to_string : t -> string
