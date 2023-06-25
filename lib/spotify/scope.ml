type t =
  [ `Ugc_image_upload
  | `User_read_playback_state
  | `User_modify_playback_state
  | `User_read_currently_playing
  | `App_remote_control
  | `Streaming
  | `Playlist_read_private
  | `Playlist_read_collaborative
  | `Playlist_modify_private
  | `Playlist_modify_public
  | `User_follow_modify
  | `User_follow_read
  | `User_read_playback_position
  | `User_top_read
  | `User_read_recently_played
  | `User_library_modify
  | `User_library_read
  | `User_read_email
  | `User_read_private
  | `User_soa_link
  | `User_soa_unlink
  | `User_manage_entitlements
  | `User_manage_partner
  | `User_create_partner ]

let to_string = function
  | `Ugc_image_upload -> "ugc-image-upload"
  | `User_read_playback_state -> "user-read-playback-state"
  | `User_modify_playback_state -> "user-modify-playback-state"
  | `User_read_currently_playing -> "user-read-currently-playing"
  | `App_remote_control -> "app-remote-control"
  | `Streaming -> "streaming"
  | `Playlist_read_private -> "playlist-read-private"
  | `Playlist_read_collaborative -> "playlist-read-collaborative"
  | `Playlist_modify_private -> "playlist-modify-private"
  | `Playlist_modify_public -> "playlist-modify-public"
  | `User_follow_modify -> "user-follow-modify"
  | `User_follow_read -> "user-follow-read"
  | `User_read_playback_position -> "user-read-playback-position"
  | `User_top_read -> "user-top-read"
  | `User_read_recently_played -> "user-read-recently-played"
  | `User_library_modify -> "user-library-modify"
  | `User_library_read -> "user-library-read"
  | `User_read_email -> "user-read-email"
  | `User_read_private -> "user-read-private"
  | `User_soa_link -> "user-soa-link"
  | `User_soa_unlink -> "user-soa-unlink"
  | `User_manage_entitlements -> "user-manage-entitlements"
  | `User_manage_partner -> "user-manage-partner"
  | `User_create_partner -> "user-create-partner"
  | #t -> .

let of_string = function
  | "ugc-image-upload" -> `Ugc_image_upload
  | "user-read-playback-state" -> `User_read_playback_state
  | "user-modify-playback-state" -> `User_modify_playback_state
  | "user-read-currently-playing" -> `User_read_currently_playing
  | "app-remote-control" -> `App_remote_control
  | "streaming" -> `Streaming
  | "playlist-read-private" -> `Playlist_read_private
  | "playlist-read-collaborative" -> `Playlist_read_collaborative
  | "playlist-modify-private" -> `Playlist_modify_private
  | "playlist-modify-public" -> `Playlist_modify_public
  | "user-follow-modify" -> `User_follow_modify
  | "user-follow-read" -> `User_follow_read
  | "user-read-playback-position" -> `User_read_playback_position
  | "user-top-read" -> `User_top_read
  | "user-read-recently-played" -> `User_read_recently_played
  | "user-library-modify" -> `User_library_modify
  | "user-library-read" -> `User_library_read
  | "user-read-email" -> `User_read_email
  | "user-read-private" -> `User_read_private
  | "user-soa-link" -> `User_soa_link
  | "user-soa-unlink" -> `User_soa_unlink
  | "user-manage-entitlements" -> `User_manage_entitlements
  | "user-manage-partner" -> `User_manage_partner
  | "user-create-partner" -> `User_create_partner
  | _ -> failwith "Invalid scope"

let to_string_list scopes = List.map to_string scopes
let of_string_list scopes = List.map of_string scopes
