// Loops algorithm for cycle counting

class Loops(n: Int) {
    private val seed = IntArray(n) { it }
    private val ends = IntArray(n)
    private var sets = 0

    fun reset(size: Int) {
        seed.copyInto(ends, 0, 0, size)
        sets = 0
    }

    fun unite(a: Int, b: Int) {
        val ea = ends[a]
        val eb = ends[b]
        if (ea == b) sets += 1
        else {
            ends[ea] = eb
            ends[eb] = ea
        }
    }

    val setCount: Int get() = sets
}
