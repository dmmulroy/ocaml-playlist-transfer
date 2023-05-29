module type MusicService = sig
  type t
  type config
  type error

  val init : config -> t Lwt.t
end
