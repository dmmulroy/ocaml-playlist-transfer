include module type of Cohttp
include module type of Cohttp_lwt
include module type of Cohttp_lwt_unix

module Body : sig
  include module type of Body

  val to_yojson : t -> (Yojson.Safe.t, string) result Lwt.t
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

module Code : sig
  include module type of Code

  val reason_phrase_of_status_code : status_code -> string
  val pp_status_code : Format.formatter -> status_code -> unit
end

module Header : sig
  include module type of Header

  val add_unless_exists : t -> t -> t
  val empty : t
end

module Uri : sig
  include module type of Uri

  val to_yojson : t -> Yojson.Safe.t
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

module Client : sig
  include module type of Client

  val get :
    ?headers:Header.t -> Uri.t -> (Cohttp.Response.t * Cohttp_lwt__Body.t) Lwt.t

  val post :
    ?headers:Header.t ->
    ?body:Body.t ->
    Uri.t ->
    (Cohttp.Response.t * Cohttp_lwt__Body.t) Lwt.t

  val put :
    ?headers:Header.t ->
    ?body:Body.t ->
    Uri.t ->
    (Cohttp.Response.t * Cohttp_lwt__Body.t) Lwt.t

  val delete :
    ?headers:Header.t ->
    ?body:Body.t ->
    Uri.t ->
    (Cohttp.Response.t * Cohttp_lwt__Body.t) Lwt.t
end

module Cohttp_request : sig
  include module type of Cohttp_lwt_unix.Request

  val uri : t -> Uri.t
end

module Request : sig
  type t

  val body : t -> Body.t
  val headers : t -> Header.t
  val meth : t -> [ `GET | `POST | `PUT | `DELETE ]
  val uri : t -> Uri.t
  val set_body : t -> Body.t -> t
  val set_headers : t -> Header.t -> t
  val set_meth : t -> [ `GET | `POST | `PUT | `DELETE ] -> t
  val set_uri : t -> Uri.t -> t

  val make :
    ?headers:Header.t ->
    ?body:Body.t ->
    meth:[ `GET | `POST | `PUT | `DELETE ] ->
    uri:Uri.t ->
    unit ->
    t
end

module Response : sig
  type t

  val body : t -> Body.t
  val headers : t -> Header.t
  val status : t -> Code.status_code
  val is_success : t -> bool
  val is_error : t -> bool

  val make :
    ?headers:Header.t -> ?body:Body.t -> status:Code.status_code -> unit -> t
end
