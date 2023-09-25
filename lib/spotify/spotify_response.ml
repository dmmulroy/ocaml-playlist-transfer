type 'a t = { data : 'a; page : Pagination.t } [@@deriving yojson]

let make ?(page = Pagination.empty) data = { data; page }
