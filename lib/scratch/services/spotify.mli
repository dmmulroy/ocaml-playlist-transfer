type t
type 'a spotify_result = ('a, [ `SpotifyApiError of string ]) result Lwt.t

val init : client_id:string -> client_secret:string -> t spotify_result
val to_string : t -> string
