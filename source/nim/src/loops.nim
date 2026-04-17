# Loops algorithm for cycle counting

import std/sequtils

type
  Loops* = object
    ends: seq[int]
    sets: int

proc create*(n: int): Loops =
  result.ends = toSeq(0..<n)
  result.sets = 0

proc reset*(rel: var Loops, n: int) =
  for i in 0..<n:
    rel.ends[i] = i
  rel.sets = 0

proc unite*(rel: var Loops, a, b: int) =
  let ea = rel.ends[a]
  let eb = rel.ends[b]
  
  if ea == b:
    inc rel.sets
  else:
    rel.ends[ea] = eb
    rel.ends[eb] = ea

proc setCount*(rel: Loops): int =
  rel.sets

const name* = "Loops"
