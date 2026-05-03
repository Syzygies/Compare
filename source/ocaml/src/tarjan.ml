(* Tarjan union-find algorithm for cycle counting *)

type t =
  { root : int array;
    mutable sets : int }

let create n =
  { root = Array.init n Fun.id;
    sets = n }

let reset t n =
  for i = 0 to n - 1 do
    t.root.(i) <- i
  done;
  t.sets <- n

let find t a =
  let here = ref a in
  while t.root.(!here) <> !here do
    here := t.root.(!here)
  done;

  let top = !here in
  here := a;

  while t.root.(!here) <> top do
    let next = t.root.(!here) in
    t.root.(!here) <- top;
    here := next
  done;
  top

let unite t a b =
  let a = find t a in
  let b = find t b in

  if a <> b then
    ( t.sets <- t.sets - 1;
      t.root.(a) <- b )

let set_count t = t.sets
