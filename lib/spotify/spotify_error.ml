open Shared

include Error.Make (struct
  let domain = `Spotify
end)
