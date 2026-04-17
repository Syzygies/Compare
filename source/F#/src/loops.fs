// Loops algorithm for cycle counting

module Loops

type T =
   { ends : int array
     mutable sets : int }

let create n =
   { ends = Array.init n (fun x -> x)
     sets = 0 }

let reset t n =
   for i = 0 to n - 1 do
      t.ends.[i] <- i

   t.sets <- 0

let unite t a b =
   let ea = t.ends.[a]
   let eb = t.ends.[b]

   if ea = b then
      t.sets <- t.sets + 1
   else
      t.ends.[ea] <- eb
      t.ends.[eb] <- ea

let setCount t = t.sets
let name = "Loops"
