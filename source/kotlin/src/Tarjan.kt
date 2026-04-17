// Tarjan union-find algorithm for cycle counting

class Tarjan(n: Int) {
    private val root = IntArray(n) { it }
    private var sets = n

    fun reset(size: Int) {
        for (i in 0 until size) root[i] = i
        sets = size
    }

    fun find(a: Int): Int {
        var current = a
        while (root[current] != current) current = root[current]
        val r = current
        current = a
        while (root[current] != r) {
            val next = root[current]
            root[current] = r
            current = next
        }
        return r
    }

    fun unite(a: Int, b: Int) {
        val ra = find(a)
        val rb = find(b)
        if (ra != rb) {
            sets -= 1
            root[ra] = rb
        }
    }

    val setCount: Int get() = sets
}
