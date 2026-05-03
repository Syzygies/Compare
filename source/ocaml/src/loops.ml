(* Loops algorithm for cycle counting *)

type t =
  { ends : int array;
    mutable sets : int }

let create n =
  { ends = Array.init n Fun.id;
    sets = 0 }

let reset t n =
  for i = 0 to n - 1 do
    t.ends.(i) <- i
  done;
  t.sets <- 0

let unite t a b =
  let ea = t.ends.(a) in
  let eb = t.ends.(b) in

  if ea = b then t.sets <- t.sets + 1
  else
    ( t.ends.(ea) <- eb;
      t.ends.(eb) <- ea )

let set_count t = t.sets
