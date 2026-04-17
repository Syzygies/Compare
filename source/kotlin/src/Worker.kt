// Worker module: hot loop performance-critical code

// Select Tarjan or Loops
typealias Relations = Tarjan; const val name = "Tarjan"

object Worker {

    // Heap's algorithm: tally all perms with a fixed length k prefix
    private fun tallyPerms(perm: IntArray, k: Int, work: (IntArray) -> Unit) {
        val n = perm.size

        fun swap(i: Int, j: Int) {
            val tmp = perm[i]; perm[i] = perm[j]; perm[j] = tmp
        }

        fun generate(j: Int) {
            if (j < k) { work(perm); return }
            generate(j - 1)
            var i = k
            while (i < j) {
                if ((j - k) % 2 == 0) swap(k, j) else swap(i, j)
                generate(j - 1)
                i += 1
            }
        }

        generate(n - 1)
    }

    // Count cycles in a signed permutation
    private fun countCycles(n: Int, perm: IntArray, signs: Int, rel: Relations): Int {
        rel.reset(2 * n)
        for (i in 0 until n) {
            val j = perm[i]
            if (((signs shr i) and 1) == 1) {
                rel.unite(i, j + n)
                rel.unite(i + n, j)
            } else {
                rel.unite(i, j)
                rel.unite(i + n, j + n)
            }
        }
        return rel.setCount
    }

    // Tally cycle counts across all signs for one perm
    private fun tallySigns(n: Int, perm: IntArray, tally: LongArray, rel: Relations) {
        val maxBits = 1 shl n
        for (signs in 0 until maxBits) {
            val cycles = countCycles(n, perm, signs, rel)
            val index = 2 * n - cycles
            tally[index] += 1
        }
    }

    // Process one parcel: tally all cycle counts with given prefix
    fun runPrefix(n: Int, k: Int, prefix: IntArray): LongArray {
        val perm = prefix.copyOf()
        val tally = LongArray(2 * n)
        val rel = Relations(2 * n)
        tallyPerms(perm, k) { p -> tallySigns(n, p, tally, rel) }
        return tally
    }
}
