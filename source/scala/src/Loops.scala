// Loops algorithm for cycle counting

class Loops(n: Int):
  private val seed = Array.tabulate(n)(i => i)
  private val ends = new Array[Int](n)
  private var sets = 0

  def reset(size: Int): Unit =
    System.arraycopy(seed, 0, ends, 0, size)
    sets = 0

  def unite(a: Int, b: Int): Unit =
    val ea = ends(a)
    val eb = ends(b)
    if ea == b then sets += 1
    else
      ends(ea) = eb
      ends(eb) = ea

  def setCount: Int = sets
