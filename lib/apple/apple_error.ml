open Shared

include Error.Make (struct
  let domain = `Apple
end)
