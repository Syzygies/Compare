// Tarjan union-find algorithm for cycle counting

class Tarjan(n: Int):
  private val seed = Array.tabulate(n)(i => i)
  private val root = new Array[Int](n)
  private var sets = n

  def reset(size: Int): Unit =
    System.arraycopy(seed, 0, root, 0, size)
    sets = size

  def find(a: Int): Int =
    var here = a
    while root(here) != here do here = root(here)
    val r = here
    here = a
    while root(here) != r do
      val next = root(here)
      root(here) = r
      here = next
    r

  def unite(a: Int, b: Int): Unit =
    val ra = find(a)
    val rb = find(b)
    if ra != rb then
      sets -= 1
      root(ra) = rb

  def setCount: Int = sets
