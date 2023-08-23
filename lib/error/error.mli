type t = {
  cause : t option;
  domain : [ `Apple | `Spotify ];
  source :
    [ `Auth
    | `Http of
      Http.Code.status_code * [ `GET | `POST | `PUT | `DELETE ] * Http.Uri.t
    | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
    | `Source of string ];
  message : string;
  timestamp : Ptime.t;
}

val to_string : t -> string

module type S = sig
  val make :
    ?cause:t ->
    source:
      [ `Auth
      | `Http of
        Http.Code.status_code * [ `GET | `POST | `PUT | `DELETE ] * Http.Uri.t
      | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
      | `Source of string ] ->
    string ->
    t
end

module Apple : S
module Spotify : S
