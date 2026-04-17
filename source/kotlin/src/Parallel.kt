// Parallel map with atomic work stealing

import java.util.concurrent.ThreadLocalRandom
import java.util.concurrent.atomic.AtomicInteger

object Parallel {
    fun <T, R> map(cores: Int, tasks: Array<T>, run: (T) -> R): List<R> {
        val count = tasks.size
        val next = AtomicInteger(0)
        val results = arrayOfNulls<Any>(count)

        // Shuffle work order for load balancing
        val order = IntArray(count) { it }
        val rng = ThreadLocalRandom.current()
        for (i in count - 1 downTo 1) {
            val j = rng.nextInt(i + 1)
            val tmp = order[i]; order[i] = order[j]; order[j] = tmp
        }

        val worker = Runnable {
            var index = next.getAndIncrement()
            while (index < count) {
                val idx = order[index]
                results[idx] = run(tasks[idx])
                index = next.getAndIncrement()
            }
        }

        val threads = List(cores - 1) { Thread(worker).also { it.start() } }
        worker.run()
        threads.forEach { it.join() }
        @Suppress("UNCHECKED_CAST")
        return results.map { it as R }
    }
}
