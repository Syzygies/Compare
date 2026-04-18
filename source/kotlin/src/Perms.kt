// Signed Permutation Cycle Counting

import kotlin.system.exitProcess

const val version = 1

// Generate initial permutation for each possible prefix
fun enumPrefixes(n: Int, k: Int): List<IntArray> {
    fun pick(k: Int, prefix: List<Int>, rest: List<Int>): List<IntArray> =
        if (k == 0) listOf((prefix.reversed() + rest).toIntArray())
        else rest.flatMap { x -> pick(k - 1, listOf(x) + prefix, rest - x) }
    return pick(k, emptyList(), (0 until n).toList())
}

// Distribute work parcels and combine results
fun runParcels(n: Int, k: Int, cores: Int): LongArray {
    val tasks = enumPrefixes(n, k).toTypedArray()
    val results = Parallel.map(cores, tasks) { Worker.runPrefix(n, k, it) }
    val acc = LongArray(2 * n)
    for (r in results) for (i in 0 until 2 * n) acc[i] += r[i]
    return acc
}

// Parse command-line arguments
fun parseArgs(args: Array<String>): Triple<Int, Int, Int>? {
    if (args.size != 3) return null
    val n = args[0].toIntOrNull() ?: return null
    val p = args[1].toIntOrNull() ?: return null
    val c = args[2].toIntOrNull() ?: return null
    return Triple(n, p, c)
}

// Main entry point
fun main(args: Array<String>) {
    val parsed = parseArgs(args)
    if (parsed == null) {
        println("Required arguments: n prefix cores")
        exitProcess(1)
    }
    val (n, prefix, cores) = parsed
    println("$name v$version, n = $n, prefix = $prefix, cores = $cores")
    val result = runParcels(n, prefix, cores)
    Answers.check(n, result)
}
