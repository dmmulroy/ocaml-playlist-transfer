open Shared

include Error.Make (struct
  let domain = `Transfer
end)
