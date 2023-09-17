module Track = Track
module Playlist = Playlist

module Internal_error = struct
  type t = [ `Empty_apple_response | `Unhandled_error of string ]

  let to_string = function
    | `Empty_apple_response ->
        "The `data` list returned from `Apple.Library_playlist.create` was \
         empty"
    | `Unhandled_error str -> "An unhandled error occurred: " ^ str
    | #t -> .
    | _ -> "An unhandled error occurred"

  let to_error ?(map_msg = fun str -> `Unhandled_error str)
      ?(source = `Source "Transfer") err =
    let message =
      (match err with `Msg str -> map_msg str | _ as err' -> err')
      |> to_string
    in
    Transfer_error.make ~source message
end
