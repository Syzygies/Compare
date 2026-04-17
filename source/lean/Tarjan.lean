-- Signed Permutation Cycle Counting

def version : Nat := 13

namespace Sets -- Tarjan

structure State where
  root : Array Nat
  sets : Nat

def name := "Tarjan"

def create (n : Nat) : State :=
  { root := Array.range n, sets := n }

def reset (s : State) (n : Nat) : State :=
  { s with root := Array.range n, sets := n }

partial def find (root : Array Nat) (a : Nat) : (Nat × Array Nat) :=
  let parent := root[a]!
  if parent == a then
    (a, root)
  else
    let (root_val, new_root_arr) := find root parent
    if root[a]! == root_val then
      (root_val, new_root_arr)
    else
      (root_val, new_root_arr.set! a root_val)

def unite (s : State) (a b : Nat) : State :=
  let (a_root, r1) := find s.root a
  let (b_root, r2) := find r1 b
  if a_root != b_root then
    { root := r2.set! a_root b_root, sets := s.sets - 1 }
  else
    { s with root := r2 }

def set_count (s : State) : Nat :=
  s.sets

end Sets -- Tarjan

-- Generate all prefix parcels for distributing work across cores
partial def prefixes (n : Nat) (k : Nat) : List (List Nat) :=
  if k == 0 then [[]]
  else
     (prefixes n (k-1)).flatMap <| fun p =>
      (List.range n).filter (fun x => !p.contains x) |>.map (fun x => x :: p)

-- Tally cycle counts across all sign combinations for one permutation
def tallyCycles (nVal : Nat) (perm : Array Nat) (rel : Sets.State) : (Sets.State × Array Nat) := Id.run do
  let tally := Array.replicate (2 * nVal) 0
  let mut current_rel := rel
  let mut current_tally := tally
  for signBits in [0:(1 <<< nVal)] do
    let mut rel_for_perm := Sets.reset current_rel (2 * nVal)
    for i in [0:nVal] do
      let j := perm[i]!
      let i0 := 2*i; let i1 := i0+1
      let j0 := 2*j; let j1 := j0+1

      if (signBits >>> i) &&& 1 != 0 then
        rel_for_perm := Sets.unite rel_for_perm i0 j1
        rel_for_perm := Sets.unite rel_for_perm i1 j0
      else
        rel_for_perm := Sets.unite rel_for_perm i0 j0
        rel_for_perm := Sets.unite rel_for_perm i1 j1

    let cycles := Sets.set_count rel_for_perm
    let idx := 2 * nVal - cycles
    if idx < current_tally.size then
      current_tally := current_tally.modify idx (· + 1)
    current_rel := rel_for_perm
  return (current_rel, current_tally)

-- Top-level helper for Heap's algorithm, operating in the ST monad
partial def heapPermute (nVal : Nat) (prefixLen : Nat) (k : Nat) (arr : Array Nat) (rel : Sets.State) (tally : Array Nat)
  : ST σ (Array Nat × Sets.State × Array Nat) := do
  if k <= prefixLen then
    let (_rel', permTally) := tallyCycles nVal arr rel
    let mut newTally := tally
    for i in [0:newTally.size] do
      newTally := newTally.modify i (· + permTally[i]!)
    return (arr, rel, newTally)
  else
    let (arrAfter, relAfter, tallyAfter) ← heapPermute nVal prefixLen (k - 1) arr rel tally
    let mut arrLoop := arrAfter
    let mut relLoop := relAfter
    let mut tallyLoop := tallyAfter
    for i in [prefixLen:k-1] do
      let j := if (k - prefixLen) % 2 == 0 then i else prefixLen
      let temp := arrLoop[j]!;
      arrLoop := arrLoop.set! j arrLoop[k-1]! |>.set! (k-1) temp
      let (arrNew, relNew, tallyNew) ← heapPermute nVal prefixLen (k-1) arrLoop relLoop tallyLoop
      arrLoop := arrNew
      relLoop := relNew
      tallyLoop := tallyNew
    return (arrLoop, relLoop, tallyLoop)

-- Process one prefix parcel: generate all permutations and tally their cycles
def processParcel (nVal : Nat) (prefixList : List Nat) : Array Nat :=
  let initialArr := Id.run do
    let mut arr := Array.range nVal
    for (val, i) in prefixList.zipIdx do
      if let some pos := arr.findIdx? (· == val) then
        if pos != i then
          let temp := arr[i]!;
          arr := arr.set! i arr[pos]! |>.set! pos temp
    return arr

  runST fun _ => do
    let rel_state := Sets.create (2 * nVal)
    let parcelTally := Array.replicate (2 * nVal) 0
    let (_finalArr, _finalRel, finalTally) ← heapPermute nVal prefixList.length nVal initialArr rel_state parcelTally
    return finalTally

-- Distribute parcels across worker domains and combine results
partial def chunkList {α : Type} (xs : List α) (chunkSize : Nat) : List (List α) :=
  if xs.isEmpty then []
  else xs.take chunkSize :: chunkList (xs.drop chunkSize) chunkSize

-- Compute cycle distribution for all signed permutations
def computeTally (nVal : Nat) (prefixLen : Nat) (cores : Nat) : IO (Array Nat) := do
  let prefixList := prefixes nVal prefixLen

  let chunkSize := if prefixList.isEmpty then 0 else (prefixList.length + cores - 1) / cores
  let chunks := if chunkSize == 0 then [] else chunkList prefixList chunkSize

  let tasks ← chunks.mapM fun chunk => IO.asTask do
    let mut localTally := Array.replicate (2 * nVal) 0
    for p in chunk do
      let parcelTally := processParcel nVal p
      for i in [0:2*nVal] do
        localTally := localTally.modify i (· + parcelTally[i]!)
    return localTally

  let mut totalTally := Array.replicate (2 * nVal) 0
  for task in tasks do
    match ← IO.wait task with
    | .ok parcelTally =>
      for i in [0:2*nVal] do
        totalTally := totalTally.modify i (· + parcelTally[i]!)
    | .error e => throw e
  return totalTally

-- Known correct cycle distributions for n=1 through n=12
def answers : Array (Array Nat) := #[
  #[], #[1, 1], #[1, 2, 3, 2], #[1, 3, 9, 13, 14, 8],
  #[1, 4, 18, 40, 81, 100, 92, 48],
  #[1, 5, 30, 90, 265, 501, 840, 940, 784, 384],
  #[1, 6, 45, 170, 655, 1666, 3991, 6790, 10124, 10568, 8224, 3840],
  #[1, 7, 63, 287, 1365, 4361, 13517, 30773, 64806, 102172, 140280, 138880, 102528, 46080],
  #[1, 8, 84, 448, 2534, 9744, 36988, 105344, 284817, 597800, 1149736, 1709568, 2205328, 2092928, 1481472, 645120],
  #[1, 9, 108, 660, 4326, 19446, 87276, 298236, 981969, 2568121, 6304608, 12424104, 22310672, 31651344, 38859648, 35613440, 24348672, 10321920],
  #[1, 10, 135, 930, 6930, 35652, 184590, 735540, 2851173, 8918338, 26548171, 64954890, 148217720, 277595888, 472103088, 644197280, 759435776, 675712512, 448598016, 185794560],
  #[1, 11, 165, 1265, 10560, 61182, 358842, 1633170, 7278513, 26480311, 92489969, 269869821, 744136030, 1724911408, 3714053376, 6668218128, 10845694816, 14319093888, 16313026048, 14148642816, 9157754880, 3715891200],
  #[1, 12, 198, 1672, 15455, 99572, 652344, 3338016, 16806207, 69688564, 279097566, 944926632, 3048785169, 8406183500, 21809957444, 48330322480, 99223087216, 171865587520, 269237405888, 345481734400, 382192970752, 324143788032, 205186498560, 81749606400]
]

-- Entry point: command-line parsing and program execution
def main (args : List String) : IO UInt32 := do
  let stdout ← IO.getStdout
  let stderr ← IO.getStderr
  if args.length < 3 then
    stderr.putStrLn "Error: Required arguments: n prefix cores"
    return 1
  let n? := (args[0]!).toNat?
  let prefix? := (args[1]!).toNat?
  let cores? := (args[2]!).toNat?
  match n?, prefix?, cores? with
  | some nVal, some prefixLen, some coresVal =>
    if nVal < 1 || nVal > 12 then
      stderr.putStrLn "Error: n must be in range 1..12"
      return 1
    if prefixLen > nVal then
      stderr.putStrLn s!"Error: prefix must be in range 0..{nVal}"
      return 1

    stdout.putStrLn s!"{Sets.name} v{version}, n = {nVal}, prefix = {prefixLen}, cores = {coresVal}"

    let result ← computeTally nVal prefixLen coresVal
    let resultStr := " ".intercalate (result.toList.map toString)
    stdout.putStrLn resultStr

    if nVal <= 12 && nVal < answers.size then
      let expected := answers[nVal]!
      if result == expected then
        stdout.putStrLn "✓"
      else
        stdout.putStrLn "✗"
        let expectedStr := " ".intercalate (expected.toList.map toString)
        stdout.putStrLn expectedStr
    else
      stdout.putStrLn "?"
    return 0
  | _, _, _ =>
    stderr.putStrLn "Error: Invalid arguments"
    return 1