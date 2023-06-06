module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

type get_featured_playlists_request = {
  country : string;
  locale : string;
  timestamp : string;
  limit : int;
  offset : int;
}

let get_featured_playlists _client _request = Lwt.return_ok ()
(* let endpoint = "https://api.spotify.com/v1/browse/featured-playlists" in *)
(* let body =   *)
