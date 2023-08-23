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
[@@deriving show]

let make ?cause ~domain ~source message =
  { cause; domain; source; message; timestamp = Ptime_clock.now () }

let to_string = show

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

module Apple : S = struct
  let make = make ~domain:`Apple
end

module Spotify : S = struct
  let make = make ~domain:`Spotify
end
