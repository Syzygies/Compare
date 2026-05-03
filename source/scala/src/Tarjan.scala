// Tarjan union-find algorithm for cycle counting

class Tarjan(n: Int):
  val root = new Array[Int](n)
  var sets = n

  def reset(size: Int): Unit =
    var i = 0
    while i < size do
      root(i) = i
      i += 1
    sets = size

  def find(a: Int): Int =
    var here = a
    while root(here) != here do
      here = root(here)

    val top = here
    here = a

    while root(here) != top do
      val next = root(here)
      root(here) = top
      here = next
    top

  def unite(a: Int, b: Int): Unit =
    val ra = find(a)
    val rb = find(b)

    if ra != rb then
      sets -= 1
      root(ra) = rb

  def setCount: Int = sets
