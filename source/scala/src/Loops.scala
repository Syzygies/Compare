// Loops algorithm for cycle counting

class Loops(n: Int):
  val ends = new Array[Int](n)
  var sets = 0

  def reset(size: Int): Unit =
    var i = 0
    while i < size do
      ends(i) = i
      i += 1
    sets = 0

  def unite(a: Int, b: Int): Unit =
    val ea = ends(a)
    val eb = ends(b)

    if ea == b then sets += 1
    else
      ends(ea) = eb
      ends(eb) = ea

  def setCount: Int = sets
