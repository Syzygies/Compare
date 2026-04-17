// Loops algorithm for cycle counting

class Loops(n: Int) {
    private val ends = IntArray(n) { it }
    private var sets = 0

    fun reset(size: Int) {
        for (i in 0 until size) ends[i] = i
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
