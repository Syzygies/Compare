// Parallel map with atomic work stealing (Kotlin/Native)

import kotlin.concurrent.AtomicInt
import kotlin.native.concurrent.TransferMode
import kotlin.native.concurrent.Worker
import kotlin.random.Random

object Parallel {
    private class Context<T, R>(
        val tasks: Array<T>,
        val order: IntArray,
        val next: AtomicInt,
        val results: Array<Any?>,
        val run: (T) -> R,
    )

    private fun <T, R> runWorker(ctx: Context<T, R>) {
        val count = ctx.tasks.size
        var index = ctx.next.incrementAndGet() - 1
        while (index < count) {
            val idx = ctx.order[index]
            ctx.results[idx] = ctx.run(ctx.tasks[idx])
            index = ctx.next.incrementAndGet() - 1
        }
    }

    fun <T, R> map(cores: Int, tasks: Array<T>, run: (T) -> R): List<R> {
        val count = tasks.size
        val results = arrayOfNulls<Any>(count)

        // Shuffle work order for load balancing
        val order = IntArray(count) { it }
        val rng = Random.Default
        for (i in count - 1 downTo 1) {
            val j = rng.nextInt(i + 1)
            val tmp = order[i]; order[i] = order[j]; order[j] = tmp
        }

        val ctx = Context(tasks, order, AtomicInt(0), results, run)

        val workers = List(cores - 1) { Worker.start() }
        val futures = workers.map { w ->
            w.execute(TransferMode.UNSAFE, { ctx }) { runWorker(it) }
        }

        runWorker(ctx)
        futures.forEach { it.result }
        workers.forEach { it.requestTermination().result }

        @Suppress("UNCHECKED_CAST")
        return results.map { it as R }
    }
}
