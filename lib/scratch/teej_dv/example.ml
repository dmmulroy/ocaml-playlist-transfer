module CategoryStorage = Model_storage.Make (struct
  open Model_storage
  include Model.Category
  include Storage.StringStorage

  let encode = function
    | Article -> Ok "article"
    | Video -> Ok "video"
    | Website -> Ok "website"
    | Twitch -> Ok "twitch"

  let decode t =
    match String.lowercase_ascii t with
    | "article" -> Ok Article
    | "video" -> Ok Video
    | "website" -> Ok Website
    | "twitch" -> Ok Twitch
    | _ -> Error "Not found"
end)
