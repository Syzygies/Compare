// Parallel map with atomic work stealing

import java.util.concurrent.atomic.AtomicInteger

object Parallel:
  def map[T, R: reflect.ClassTag](
      cores: Int,
      init: R,
      run: T => R,
      tasks: Array[T]
  ): Array[R] =
    val count = tasks.length
    val next = AtomicInteger(0)
    val results = Array.fill(count)(init)

    // Shuffle work order for load balancing
    val order = Array.tabulate(count)(identity)
    val rng = java.util.concurrent.ThreadLocalRandom.current()
    var i = count - 1
    while i > 0 do
      val j = rng.nextInt(i + 1)
      val tmp = order(i); order(i) = order(j); order(j) = tmp
      i -= 1

    def worker(): Unit =
      var index = next.getAndIncrement()
      while index < count do
        val idx = order(index)
        results(idx) = run(tasks(idx))
        index = next.getAndIncrement()

    val threads = Array.tabulate(cores - 1) { _ =>
      val t = Thread((() => worker()): Runnable)
      t.start()
      t
    }

    worker()
    threads.foreach(_.join())
    results
