module List = struct
  let chunk (chunk_size : int) (list : 'a list) =
    let rec aux (acc : 'a list list) (chunk : 'a list)
        (current_chunk_size : int) (list' : 'a list) =
      match list' with
      | [] -> if chunk = [] then acc else List.rev chunk :: acc
      | hd :: tl ->
          if current_chunk_size < chunk_size then
            aux acc (hd :: chunk) (current_chunk_size + 1) tl
          else aux (List.rev chunk :: acc) [ hd ] 1 tl
    in
    List.rev (aux [] [] 0 list)

  let hd_opt (list : 'a list) : 'a option =
    match list with [] -> None | hd :: _ -> Some hd
end
