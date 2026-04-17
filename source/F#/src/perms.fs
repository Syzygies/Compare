// Signed Permutation Cycle Counting

open System
open System.Linq
open System.Collections.Generic

let version = 8

// Select Tarjan or Loops
module Sets = Tarjan

// Generate initial permutation for each possible prefix
let enumPrefixes n k =
   let rest = List.init n id

   let rec pick k prefix rest =
      if k = 0 then
         [ prefix @ rest ]
      else
         [ for x in rest do
              let sans_x = List.filter ((<>) x) rest
              yield! pick (k - 1) (x :: prefix) sans_x ]

   pick k [] rest

// Heap's algorithm: tally all perms with a fixed length k prefix
let tallyPerms perm k work =
   let n = Array.length perm
   let swap = Parallel.swap

   let rec generate j =
      if j < k then
         work perm
      else
         generate (j - 1)

         for i = k to j - 1 do
            if (j - k) % 2 = 0 then swap perm k j else swap perm i j
            generate (j - 1)

   generate (n - 1)

// Count cycles in a signed permutation
let countCycles n (perm : int array) signs rel =
   Sets.reset rel (2 * n)

   for i = 0 to n - 1 do
      let j = perm.[i]

      if (signs >>> i) &&& 1 = 1 then
         Sets.unite rel i (j + n)
         Sets.unite rel (i + n) j
      else
         Sets.unite rel i j
         Sets.unite rel (i + n) (j + n)

   Sets.setCount rel

// Tally cycle counts across all signs for one perm
let tallySigns n (perm : int[]) (tally : int64[]) rel =
   let maxBits = 1 <<< n

   for signs = 0 to maxBits - 1 do
      let cycles = countCycles n perm signs rel
      let index = 2 * n - cycles
      tally.[index] <- tally.[index] + 1L

// Process one parcel: tally all cycle counts with given prefix
let runPrefix n k perm =
   let perm = Array.ofList perm
   let tally : int64 array = Array.zeroCreate (2 * n)
   let rel = Sets.create (2 * n)
   let work perm = tallySigns n perm tally rel

   tallyPerms perm k work
   tally

// Entry point: distribute work parcels and combine results
let runParcels n k cores =
   let zero = Array.zeroCreate (2 * n)

   enumPrefixes n k
   |> Parallel.map cores zero (runPrefix n k)
   |> function
      | [] -> zero
      | head :: tail -> List.fold (Array.map2 (+)) head tail

// Parse command-line arguments
let parseArgs argv =
   match argv with
   | [| nStr ; prefixStr ; coresStr |] ->
      match
         Int32.TryParse (nStr : string),
         Int32.TryParse (prefixStr : string),
         Int32.TryParse (coresStr : string)
      with
      | (true, n), (true, prefix), (true, cores) ->
         Some (n, prefix, cores)
      | _ ->
         eprintfn "Error: All arguments must be valid integers."
         None
   | _ ->
      eprintfn "Error: Required arguments: n prefix cores"
      None

// Entry point
[<EntryPoint>]
let main argv =
   match parseArgs argv with
   | Some (n, k, cores) ->
      printfn
         "%s v%d, n = %d, prefix = %d, cores = %d"
         Sets.name
         version
         n
         k
         cores

      let result = runParcels n k cores
      Answers.check n result
      0
   | None -> 1
