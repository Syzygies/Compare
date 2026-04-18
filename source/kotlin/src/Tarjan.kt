// Tarjan union-find algorithm for cycle counting

class Tarjan(n: Int) {
    private val seed = IntArray(n) { it }
    private val root = IntArray(n)
    private var sets = n

    fun reset(size: Int) {
        seed.copyInto(root, 0, 0, size)
        sets = size
    }

    fun find(a: Int): Int {
        var here = a
        while (root[here] != here) here = root[here]
        val r = here
        here = a
        while (root[here] != r) {
            val next = root[here]
            root[here] = r
            here = next
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
