// Tarjan union-find algorithm for cycle counting

class Tarjan(n: Int):
  private val root = Array.tabulate(n)(identity)
  private var sets = n

  def reset(size: Int): Unit =
    var i = 0
    while i < size do
      root(i) = i
      i += 1
    sets = size

  def find(a: Int): Int =
    var current = a
    while root(current) != current do current = root(current)
    val r = current
    current = a
    while root(current) != r do
      val next = root(current)
      root(current) = r
      current = next
    r

  def unite(a: Int, b: Int): Unit =
    val ra = find(a)
    val rb = find(b)
    if ra != rb then
      sets -= 1
      root(ra) = rb

  def setCount: Int = sets
