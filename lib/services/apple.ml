module type AppleMusicService = sig
  type t
  type error

  val init : string -> t
  (* val get_playlists : t -> (string list, error) result *)
end

module AppleMusicService = struct
  type t = { api_key : string }
  type error = ApiError

  let init (api_key : string) = { api_key }
end
