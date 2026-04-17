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
  let current = ref a in

  while t.root.(!current) <> !current do
    current := t.root.(!current)
  done;

  let root = !current in
  current := a;

  while t.root.(!current) <> root do
    let next = t.root.(!current) in
    t.root.(!current) <- root;
    current := next
  done;

  root

let unite t a b =
  let a = find t a in
  let b = find t b in
  if a <> b then
    ( t.sets <- t.sets - 1;
      t.root.(a) <- b )

let set_count t = t.sets
let name = "Tarjan"
