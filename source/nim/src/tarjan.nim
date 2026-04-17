import std/sequtils

type
  Tarjan* = object
    root: seq[int]
    sets: int

proc create*(n: int): Tarjan =
  result.root = toSeq(0..<n)
  result.sets = n

proc reset*(rel: var Tarjan, n: int) =
  for i in 0..<n:
    rel.root[i] = i
  rel.sets = n

proc find(rel: var Tarjan, a: int): int =
  var current = a
  
  while rel.root[current] != current:
    current = rel.root[current]
  
  result = current
  current = a
  
  while rel.root[current] != result:
    let next = rel.root[current]
    rel.root[current] = result
    current = next

proc unite*(rel: var Tarjan, a, b: int) =
  let a = rel.find(a)
  let b = rel.find(b)
  
  if a != b:
    dec rel.sets
    rel.root[a] = b

proc setCount*(rel: Tarjan): int =
  rel.sets

const name* = "Tarjan"
