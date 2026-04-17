// Signed Permutation Cycle Counting

val version = 1

// Generate initial permutation for each possible prefix
def enumPrefixes(n: Int, k: Int): List[Array[Int]] =
  def pick(
      k: Int,
      prefix: List[Int],
      rest: List[Int]
  ): List[Array[Int]] =
    if k == 0 then List((prefix.reverse ++ rest).toArray)
    else
      rest.flatMap { x =>
        pick(k - 1, x :: prefix, rest.filter(_ != x))
      }
  pick(k, Nil, (0 until n).toList)

// Distribute work parcels and combine results
def runParcels(n: Int, k: Int, cores: Int): Array[Long] =
  val zero = Array.ofDim[Long](2 * n)
  val tasks = enumPrefixes(n, k).toArray
  val results =
    Parallel.map(
      cores,
      zero,
      prefix => Worker.runPrefix(n, k, prefix),
      tasks
    )
  results.foldLeft(zero) { (acc, r) =>
    acc.zip(r).map(_ + _)
  }

// Parse command-line arguments
def parseArgs(args: Array[String]): Option[(Int, Int, Int)] =
  args match
    case Array(n, prefix, cores) =>
      for
        n <- n.toIntOption
        p <- prefix.toIntOption
        c <- cores.toIntOption
      yield (n, p, c)
    case _ => None

// Main entry point
@main def perms(args: String*): Unit =
  parseArgs(args.toArray) match
    case Some((n, prefix, cores)) =>
      println(
        s"${Worker.name} v$version, n = $n, prefix = $prefix, cores = $cores"
      )
      val result = runParcels(n, prefix, cores)
      Answers.check(n, result)
    case None =>
      System.err.println("Required arguments: n prefix cores")
      sys.exit(1)
