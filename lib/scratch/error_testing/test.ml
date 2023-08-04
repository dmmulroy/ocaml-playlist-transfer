module type Error_S = sig
  type t = private [> ]
end

module Make_error (M : Error_S) : Error_S with type t = M.t = struct
  include M
end

module Request_error = Make_error (struct
  type t = [ `Request_error of int * string ]
end)

module Json_parse_error = Make_error (struct
  type t = [ `Json_parse_error ]
end)

module Error = Make_error (struct
  type t = [ Request_error.t | Json_parse_error.t ]
end)

module type Request_IO_S = sig
  type input
  type output
end

type 'a err = [ `Request_error of int * string | `Error of 'a ]

module type Request_S = sig
  type input
  type output
  type error = private [> ]

  val request : input -> (output, error err) result
  (* val request : input -> (output, error) result *)
end

module Make_request (M : Request_S) = struct
  include M
end

(* module Make_request (IO : Request_IO_S) (E : Error_S) : Request_S = struct *)
(*   type input = IO.input *)
(*   type output = IO.output *)
(*   type error = E.t *)
(* end *)
