// Tarjan union-find for cycle counting

module Tarjan

type T =
   { seed : int array
     root : int array
     mutable sets : int }

let create n =
   { seed = Array.init n (fun x -> x)
     root = Array.zeroCreate n
     sets = n }

let reset t n =
   Array.blit t.seed 0 t.root 0 n
   t.sets <- n

let find t a =
   let mutable here = a

   while t.root.[here] <> here do
      here <- t.root.[here]

   let top = here
   let mutable here = a

   while t.root.[here] <> top do
      let next = t.root.[here]
      t.root.[here] <- top
      here <- next

   top

let unite t a b =
   let a = find t a
   let b = find t b

   if a <> b then
      t.sets <- t.sets - 1
      t.root.[a] <- b

let setCount t = t.sets

let name = "Tarjan"
