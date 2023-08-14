type t = {
  cause : t option;
  domain : [ `Apple | `Spotify ];
  source :
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Json
    | `Source of string ];
  message : string;
  timestamp : Ptime.t;
}

val make :
  ?cause:t ->
  domain:[ `Apple | `Spotify ] ->
  source:
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Json
    | `Source of string ] ->
  string ->
  t

val to_string : t -> string
