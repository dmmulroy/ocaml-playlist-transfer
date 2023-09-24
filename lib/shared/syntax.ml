module Infix = struct
  module Option = struct
    (** [>>=] is an infix [Option.bind]. *)
    let ( >>= ) = Option.bind

    (** [>|=] is an infix left-to-right [Option.map]. *)
    let ( >|= ) opt_a f = Option.map f opt_a

    (** [<$>] is an infix right-to-left [Option.map]. *)
    let ( <$> ) = Option.map
  end
  (* [>>=?] is an infix operator for passing [Ok] values through
     or applying [f] to [Error] values. *)

  module Result = struct
    (** [>>=] is an infix [Result.bind]. *)
    let ( >>= ) = Result.bind

    (** [>|=] is an infix left-to-right [Result.map]. *)
    let ( >|= ) res_a f = Result.map f res_a

    (** 
      * [>|?] is an infix operator for passing [Ok] values through 
      * or applying [f] to [Error] values. 
      *)
    let ( >|? ) v f = Result.map_error f v

    (** [<$>] is an infix right-to-left [Result.map]. *)
    let ( <$> ) = Result.map
  end

  module Lwt = struct
    (** [>>=] is an infix [Lwt.bind]. *)
    let ( >>= ) = Lwt.bind

    (** [>|=] is an infix left-to-right [Lwt.map]. *)
    let ( >|= ) v f = Lwt.map f v

    (** [<$>] is an infix right-to-left [Lwt.map]. *)
    let ( <$> ) = Lwt.map
  end

  module Lwt_result = struct
    (** [>>=] is an infix [Lwt.bind]. *)
    let ( >>= ) = Lwt_result.bind

    (** 
      * [>|?] is an infix operator for passing [Ok] values through 
      * or applying [f] to [Error] values. 
      *)
    let ( >|? ) v f = Lwt_result.map_error f v

    (** 
      * [>|?*] is an infix operator for passing [Ok] values through 
      * or applying [f] to [Error Lwt.t] values. 
      *)
    let ( >|?* ) = Lwt_result.bind_lwt_error

    (** [>|=] is an infix left-to-right [Lwt.map]. *)
    let ( >|= ) v f = Lwt_result.map f v

    (** [<$>] is an infix right-to-left [Lwt.map]. *)
    let ( <$> ) = Lwt_result.map
  end
end

module Let = struct
  (** [let- var = opt] binds [var] to [v] when [opt] is [Some v] *)
  let ( let- ) = Option.bind

  (** [let@ var = res] binds [var] to [v] when [res] is [Ok v] *)
  let ( let@ ) = Result.bind

  (** [let* var = promise] binds [var] to [v] when Lwt promise [promise] resolves to [v] *)
  let ( let* ) = Lwt.bind

  (** [let+ var = promise] binds [var] to [v] when Lwt promise [promise] resolves to [Ok v] *)
  let ( let+ ) = Lwt_result.bind

  (** [let| var = res] lifts a [('ok, 'err) result] [res] to a [('ok, 'err) Lwt_result.t], removing
      the need to add [Lwt.return]s. *)
  let ( let| ) v f = Lwt_result.bind (Lwt.return v) f

  (** [let*| var = promise] lifts an ['a Lwt.t] promise into an [('a, 'err) Lwt_result.t] *)
  let ( let*| ) v f = Lwt_result.bind (Lwt.map Result.ok v) f
end
