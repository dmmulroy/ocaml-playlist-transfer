type t = {
  cause : t option;
  domain : [ `Apple | `Spotify ];
  source :
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
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
    | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
    | `Source of string ] ->
  string ->
  t

val to_string : t -> string

module Apple : sig
  val make :
    ?cause:t ->
    source:
      [ `Auth
      | `Http of Http.Code.status_code * Http.Uri.t
      | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
      | `Source of string ] ->
    string ->
    t
end

module Spotify : sig
  val make :
    ?cause:t ->
    source:
      [ `Auth
      | `Http of Http.Code.status_code * Http.Uri.t
      | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
      | `Source of string ] ->
    string ->
    t
end
