// Tarjan union-find for cycle counting

module Tarjan

type T =
   { root : int array
     mutable sets : int }

let create n =
   { root = Array.init n (fun x -> x)
     sets = n }

let reset t n =
   for i = 0 to n - 1 do
      t.root.[i] <- i

   t.sets <- n

let find t a =
   let mutable current = a

   while t.root.[current] <> current do
      current <- t.root.[current]

   let root = current
   let mutable current = a

   while t.root.[current] <> root do
      let next = t.root.[current]
      t.root.[current] <- root
      current <- next

   root

let unite t a b =
   let aRoot = find t a
   let bRoot = find t b

   if aRoot <> bRoot then
      t.sets <- t.sets - 1
      t.root.[aRoot] <- bRoot

let setCount t = t.sets

let name = "Tarjan"
