open Shared

type 'a t = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option;
  offset : int;
  previous : Http.Uri.t option;
  total : int;
}
[@@deriving yojson]

type page

(*
  val get_by_id : client:Client.t -> ?page:Page.t -> Input.t -> ((t,page), Error.t) result Lwt.t
  let+ data, page = Spotify.Playlist.get_by_id ~client input
  let+ next_page, page = match page.next with
  | some fn -> fn ()
 *)
