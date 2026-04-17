import std/[atomics, random, sequtils]

type SharedWork[T, U] = object
  tasks: ptr seq[T]
  results: ptr seq[U]
  order: ptr seq[int]
  next: ptr Atomic[int]
  count: int
  run: proc(x: T): U {.gcsafe.}

proc worker[T, U](
  work: ptr SharedWork[T, U]
) {.thread.} =

  while true:
    let index = work.next[].fetchAdd(1)
    if index >= work.count: break
    let i = work.order[][index]
    work.results[][i] = work.run(work.tasks[][i])

proc map*[T, U](
  cores: int, 
  run: proc(x: T): U {.gcsafe.}, 
  tasks: seq[T]
): seq[U] =

  let count = tasks.len
  
  var next: Atomic[int]
  var order = toSeq(0..<count)
  order.shuffle()
  
  result = newSeq[U](count)
  
  var work = SharedWork[T, U](
    tasks: unsafeAddr tasks,
    results: addr result,
    order: addr order,
    next: addr next,
    count: count,
    run: run
  )
  
  var threads = newSeq[Thread[ptr SharedWork[T, U]]](cores - 1)
  for t in threads.mitems:
    createThread(t, worker[T, U], addr work)
  
  worker(addr work)
  
  for t in threads:
    joinThread(t)
  