type t

module Fns : sig
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

include Fns.S

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

module Make (_ : Error_domain) : sig
  include S
end
