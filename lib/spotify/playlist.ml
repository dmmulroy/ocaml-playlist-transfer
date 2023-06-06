type t = unit

module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

let get_featured_playlists _client = Lwt.return_ok ()
