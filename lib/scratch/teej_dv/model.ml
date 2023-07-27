module type S = sig
  type t

  val name : string
end

module Category = struct
  type t = Video | Article | Website | Twitch

  let name = "category"
end
