// Worker module: hot loop performance-critical code

object Worker:

  // Select Tarjan or Loops
  type Relations = Tarjan; val name = "Tarjan"

  // Heap's algorithm: tally all perms with a fixed length k prefix
  private def tallyPerms(
      perm: Array[Int],
      k: Int,
      work: Array[Int] => Unit
  ): Unit =
    val n = perm.length

    def swap(i: Int, j: Int): Unit =
      val tmp = perm(i); perm(i) = perm(j); perm(j) = tmp

    def generate(j: Int): Unit =
      if j < k then work(perm)
      else
        generate(j - 1)
        var i = k
        while i < j do
          if (j - k) % 2 == 0 then swap(k, j) else swap(i, j)
          generate(j - 1)
          i += 1

    generate(n - 1)

  // Count cycles in a signed permutation
  private def countCycles(
      n: Int,
      perm: Array[Int],
      signs: Int,
      rel: Relations
  ): Int =
    rel.reset(2 * n)
    var i = 0
    while i < n do
      val j = perm(i)
      if ((signs >> i) & 1) == 1 then
        rel.unite(i, j + n)
        rel.unite(i + n, j)
      else
        rel.unite(i, j)
        rel.unite(i + n, j + n)
      i += 1
    rel.setCount

  // Tally cycle counts across all signs for one perm
  private def tallySigns(
      n: Int,
      perm: Array[Int],
      tally: Array[Long],
      rel: Relations
  ): Unit =
    val maxBits = 1 << n
    var signs = 0
    while signs < maxBits do
      val cycles = countCycles(n, perm, signs, rel)
      val index = 2 * n - cycles
      tally(index) += 1
      signs += 1

  // Process one parcel: tally all cycle counts with given prefix
  def runPrefix(n: Int, k: Int, prefix: Array[Int]): Array[Long] =
    val perm = prefix.clone()
    val tally = Array.ofDim[Long](2 * n)
    val rel = new Relations(2 * n)
    tallyPerms(perm, k, perm => tallySigns(n, perm, tally, rel))
    tally
