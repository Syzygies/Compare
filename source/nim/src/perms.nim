# Signed Permutation Cycle Counting

import std/[os, strutils, sequtils]
import loops, tarjan, answers, parallel

const version = 1

type
  Loops = loops.Loops
  Tarjan = tarjan.Tarjan

# Select Tarjan or Loops
  Sets = Tarjan

proc getName(): string =
  when Sets is Loops:
    loops.name
  else:
    tarjan.name

# Generate initial permutation for each possible prefix
proc enumPrefixes(n, k: int): seq[seq[int]] =
  let rest = toSeq(0..<n)
  
  proc pick(
    k: int, 
    prefix: seq[int],
    rest: seq[int]
  ): seq[seq[int]] =
    if k == 0:
      return @[prefix & rest]
    else:
      result = @[]
      for x in rest:
        let sansX = rest.filterIt(it != x)
        result.add(pick(k - 1, prefix & @[x], sansX))
  
  return pick(k, @[], rest)

# Process one permutation with all sign patterns
proc processPerm(
  n: int, 
  perm: seq[int], 
  tally: var seq[int], 
  rel: var Sets
) =
  let maxBits = 1 shl n
  for signs in 0..<maxBits:
    when Sets is Loops:
      loops.reset(rel, 2 * n)
    else:
      tarjan.reset(rel, 2 * n)
    
    for i in 0..<n:
      let pi = perm[i]
      if ((signs shr i) and 1) == 1:
        when Sets is Loops:
          loops.unite(rel, i, pi + n)
          loops.unite(rel, i + n, pi)
        else:
          tarjan.unite(rel, i, pi + n)
          tarjan.unite(rel, i + n, pi)
      else:
        when Sets is Loops:
          loops.unite(rel, i, pi)
          loops.unite(rel, i + n, pi + n)
        else:
          tarjan.unite(rel, i, pi)
          tarjan.unite(rel, i + n, pi + n)
    
    let cycles = when Sets is Loops:
      loops.setCount(rel)
    else:
      tarjan.setCount(rel)
    
    let index = (2 * n) - cycles
    inc tally[index]

# Heap's algorithm recursive implementation
proc heapGenerate(
  n, k, j: int, 
  perm: var seq[int], 
  tally: var seq[int], 
  rel: var Sets
) =

  if j < k:
    processPerm(n, perm, tally, rel)
  else:
    heapGenerate(n, k, j - 1, perm, tally, rel)
    for i in k..<j:
      if (j - k) mod 2 == 0:
        swap perm[k], perm[j]
      else:
        swap perm[i], perm[j]
      heapGenerate(n, k, j - 1, perm, tally, rel)

# Heap's algorithm: tally all perms with a fixed length k prefix
proc tallyPerms(
  n, k: int, 
  perm: var seq[int], 
  tally: var seq[int], 
  rel: var Sets
) =
  heapGenerate(n, k, perm.len - 1, perm, tally, rel)

# Process one parcel: tally all cycle counts with given prefix
proc runPrefix(
  n, k: int, 
  prefix: seq[int]
): seq[int] {.gcsafe.} =
  var perm = prefix
  var tally = newSeq[int](2 * n)
  var rel = when Sets is Loops:
    loops.create(2 * n)
  else:
    tarjan.create(2 * n)
  
  tallyPerms(n, k, perm, tally, rel)
  return tally

# Entry point: distribute work parcels and combine results
proc runParcels(n, k, cores: int): seq[int] =
  let zero = newSeq[int](2 * n)
  let prefixes = enumPrefixes(n, k)
  
  let parcels = parallel.map(
    cores, 
    proc(x: seq[int]): seq[int] {.gcsafe.} = runPrefix(n, k, x), 
    prefixes
  )
  
  if parcels.len == 0:
    return zero
  
  result = parcels[0]
  for i in 1..<parcels.len:
    for j in 0..<result.len:
      result[j] += parcels[i][j]

# Parse command-line arguments
proc parseArgs(): tuple[n, prefix, cores: int, valid: bool] =
  let args = commandLineParams()
  
  if args.len != 3:
    echo "Error: Required arguments: n prefix cores"
    return (0, 0, 0, false)
  
  try:
    let n = parseInt(args[0])
    let prefix = parseInt(args[1])
    let cores = parseInt(args[2])
    return (n, prefix, cores, true)
  except ValueError:
    echo "Error: All arguments must be valid integers."
    return (0, 0, 0, false)

# Main entry point
when isMainModule:
  let (n, k, cores, valid) = parseArgs()
  
  if not valid:
    quit(1)
  
  echo getName(), " v", version, ", n = ", n, ", prefix = ", k, ", cores = ", cores
  let result = runParcels(n, k, cores)
  answers.check(n, result)