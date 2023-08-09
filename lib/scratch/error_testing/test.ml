type 'a error = { error : 'a }
type http_error = [ `Http_error of int * string ] error
