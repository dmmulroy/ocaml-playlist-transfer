type t = {
  cause : t option;
  domain : [ `Apple | `Spotify | `Transfer | `Domain of string ];
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

module Fns = struct
  module type S = sig
    val cause : t -> t option
    val domain : t -> [ `Apple | `Spotify | `Transfer | `Domain of string ]
    val message : t -> string

    val source :
      t ->
      [ `Auth
      | `Http of
        Http.Code.status_code * [ `GET | `POST | `PUT | `DELETE ] * Http.Uri.t
      | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
      | `Source of string ]

    val timestamp : t -> Ptime.t
    val to_string : t -> string
  end
end

module Fns_impl : Fns.S = struct
  let cause t = t.cause
  let domain t = t.domain
  let message t = t.message
  let source t = t.source
  let timestamp t = t.timestamp
  let to_string = show
end

include Fns_impl

module type S = sig
  include Fns.S

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

module type Error_domain = sig
  val domain : [ `Apple | `Spotify | `Transfer | `Domain of string ]
end

module Make (M : Error_domain) = struct
  include Fns_impl

  let make = make ~domain:M.domain
end
