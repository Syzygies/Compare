(* Signed Permutation Cycle Counting *)

let version = 7

(* Generate initial permutation for each possible prefix *)
let enum_prefixes n k =
  let rest = List.init n Fun.id in
  let rec pick k prefix rest =
    if k = 0 then [ prefix @ rest ]
    else
      List.concat_map
        (fun x ->
          let sans_x = List.filter (( <> ) x) rest in
          pick (k - 1) (x :: prefix) sans_x)
        rest
  in
  pick k [] rest

(* Distribute work parcels and combine results *)
let run_parcels n k cores =
  let zero = Array.make (2 * n) 0 in
  enum_prefixes n k |> Parallel.map cores zero (Worker.run_prefix n k)
  |> function
  | [] -> zero
  | head :: tail -> List.fold_left (Array.map2 ( + )) head tail

(* Parse command-line arguments *)
let parse_args argv =
  match Array.to_list argv with
  | [ _; arg1; arg2; arg3 ] ->
    ( match List.map int_of_string_opt [ arg1; arg2; arg3 ] with
      | [ Some n; Some prefix; Some cores ] -> Some (n, prefix, cores)
      | _ -> None )
  | _ -> None

(* Main entry point *)
let () =
  match parse_args Sys.argv with
  | Some (n, prefix, cores) ->
      Printf.printf "%s v%d, n = %d, prefix = %d, cores = %d\n"
        Worker.name version n prefix cores;
      let result = run_parcels n prefix cores in
      Answers.check n result
  | None -> 
      Printf.eprintf "Required arguments: n prefix cores\n";
      exit 1
