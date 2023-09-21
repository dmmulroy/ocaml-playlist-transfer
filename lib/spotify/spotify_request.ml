type 'a t = { input : 'a; page : Pagination.cursor option }

let make ?page input = { input; page }
