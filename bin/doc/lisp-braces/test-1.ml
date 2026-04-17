(* Loops algorithm for cycle counting *)

type t = { ends : int array; mutable sets : int }

let create n = { ends = Array.init n Fun.id; sets = 0 }

let reset t n =
  t.sets <- 0;
  for i = 0 to n - 1 do
    t.ends.(i) <- i
  done

let unite t a b =
  let ea = t.ends.(a) in
  let eb = t.ends.(b) in
  if ea = b then t.sets <- t.sets + 1
  else (
    t.ends.(ea) <- eb;
    t.ends.(eb) <- ea)

let set_count t = t.sets
let name = "Loops"

let create n =
  { ends = Array.init n Fun.id; sets = 0 }

  let data = { outer = "a"; inner = { x = 1; y = 2 } }

let config = { name = "section {a}"; value = "config }" }

let record = { field1 = 10; (* a comment with a } brace *) field2 = 20 }

let quoted_string = { message = "He said, \"Hello, }" }

type t = {ends : int array}

type t = {
  ends : int array; mutable sets : int }

  else (
    Printf.printf "✗\n";
    data.(n) |> List.map string_of_int |> String.concat " "
    |> print_endline)
