// Loops algorithm for cycle counting

module Loops

type T =
   { seed : int array
     ends : int array
     mutable sets : int }

let create n =
   { seed = Array.init n (fun x -> x)
     ends = Array.zeroCreate n
     sets = 0 }

let reset t n =
   Array.blit t.seed 0 t.ends 0 n
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
