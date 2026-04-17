module Parallel

type Env = System.Environment
type Atomic = System.Threading.Interlocked
type Task = System.Threading.Tasks.Task
type Thread = System.Threading.Thread

let swap (arr : _[]) i j =
   let temp = arr.[i]
   arr.[i] <- arr.[j]
   arr.[j] <- temp

let map
   (cores : int)
   (init : 'b)
   (run : 'a -> 'b)
   (tasks : 'a list)
   : 'b list =
   let tasks = Array.ofList tasks
   let count = tasks.Length

   let mutable next = -1
   let order = Array.init count id

   let results = Array.create count init

   let shuffle arr =
      for i = count - 1 downto 1 do
         let j = System.Random.Shared.Next (i + 1)
         swap arr i j

   shuffle order

   let worker () =
      let rec loop () =
         let index = Atomic.Increment (&next)

         if index < count then
            let index = order.[index]
            results.[index] <- run tasks.[index]
            loop ()

      loop ()

   let workers = [| for _ in 1 .. cores - 1 -> Task.Run (worker) |]

   worker ()
   Task.WaitAll workers
   Array.toList results
