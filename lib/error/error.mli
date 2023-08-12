type t = {
  cause : t option;
  domain : [ `Apple | `Spotify | `None ];
  source :
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Json
    | `None
    | `Source of string ];
  message : string;
  raw : [ `Json of Yojson.Safe.t | `None | `Raw of string ];
  timestamp : Ptime.t;
}

val make :
  ?cause:t ->
  ?raw:[ `Json of Yojson.Safe.t | `None | `Raw of string ] ->
  domain:[ `Apple | `Spotify | `None ] ->
  source:
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Json
    | `None
    | `Source of string ] ->
  message:string ->
  unit ->
  t

val of_http :
  ?cause:t ->
  domain:[ `Apple | `Spotify | `None ] ->
  Http.Request.t * Http.Response.t ->
  t Lwt.t

val to_string : t -> string
