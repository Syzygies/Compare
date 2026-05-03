## Compare: Language Selection for Mathematical Research

This is a side-by-side comparison of programming languages, implementing a toy problem with similar characteristics to the combinatorial search that arises in my research. My immediate goal was to reconsider the language choices for my work.

Optimizing code in languages you do not know is an interesting form of tourism, only made possible by working with AI. Multiple agents were involved in this project. I am responsible line-by-line for the code in languages I seriously considered for adoption. Core algorithms are entirely mine, such as the "Loops" alternative to Tarjan union-find, or the mimimal implementation of parallel work stealing in OCaml and Scala.

This is a partial, public view of the project.

### The Problem

We tally in parallel the cycle distributions of signed permutations (elements of the hyperoctahedral group B_n). For n=10 there are n! * 2^n = 3,715,891,200 signed permutations.

### Results

Benchmarked on Apple M4 Max (12 performance cores), n=10, prefix=3.

Two algorithms are tested: **Tarjan** (union-find with path compression) and **Loops** (a simpler cycle-counting method).

#### Tarjan (complex algorithm, unpredictable memory access)

| Language | Score | Time | Variance |
|---|---:|---:|---:|
| F# | 100 | 19.24s | ±0.04s |
| Rust | 100 | 19.23s | ±0.06s |
| C++ | 97 | 19.89s | ±0.27s |
| Kotlin | 89 | 21.59s | ±0.04s |
| Scala | 87 | 22.01s | ±0.14s |
| Kotlin Native | 82 | 23.60s | ±0.03s |
| Scala Native | 74 | 26.16s | ±0.02s |
| Nim | 69 | 27.79s | ±0.04s |
| Julia | 63 | 30.76s | ±0.04s |
| Swift | 51 | 37.69s | ±0.45s |
| OCaml | 47 | 41.20s | ±0.05s |
| Chez Scheme | 45 | 42.98s | ±0.04s |
| Haskell | 36 | 53.42s | ±0.20s |
| Lean 4 | 10 | 198.63s | ±1.02s |
| Clojure | 3 | 739.51s | ±1.75s |

#### Loops (simple algorithm, predictable access patterns)

| Language | Score | Time | Variance |
|---|---:|---:|---:|
| C++ | 100 | 13.41s | ±0.21s |
| Rust | 97 | 13.78s | ±0.21s |
| F# | 91 | 14.70s | ±0.03s |
| Julia | 91 | 14.79s | ±0.09s |
| Kotlin Native | 90 | 14.85s | ±0.01s |
| Kotlin | 87 | 15.40s | ±0.09s |
| Scala | 80 | 16.74s | ±0.07s |
| Scala Native | 79 | 16.94s | ±0.03s |
| Nim | 66 | 20.27s | ±0.06s |
| Swift | 65 | 20.75s | ±0.14s |
| OCaml | 53 | 25.20s | ±0.06s |
| Chez Scheme | 49 | 27.10s | ±0.05s |
| Haskell | 38 | 35.10s | ±0.09s |
| Lean 4 | 18 | 72.63s | ±0.23s |
| Clojure | 2 | 543.40s | ±0.24s |

I could imagine committing to any language on this list. Various other languages were considered, and dropped as impractical.

#### Reading the results

**Score** normalizes throughput so the fastest language averages 100. A score of 80 means 80% as fast as the leader.

**Variance** (±) estimates the smallest timing difference that has a 50% chance of being real rather than noise. Scala Native runs are the most deterministic on both algorithms (±0.02s on Tarjan, ±0.03s on Loops) — a consequence of ahead-of-time compilation and predictable GC. C++ shows occasional drift on both algorithms (±0.27s on Tarjan, ±0.21s on Loops) and Swift on Tarjan (±0.45s), likely thermal.

**Tarjan vs Loops** reveals how well each runtime handles algorithmic complexity. JIT compilers (JVM, .NET) relatively favor Tarjan because they optimize based on observed runtime behavior — F# now ties Rust at the Tarjan crown, with C++ a close third. Ahead-of-time compilers (Rust, C++, Scala Native) show smaller gaps between the two algorithms, and C++ holds the Loops crown.

### Architecture

Each language implementation lives in `source/{language}/` with the same structure:

```
source/{language}/
  src/         Source files
  run          Build and execute script
```

The code separates into two layers:

- **Perms** (coordination): Generates work parcels, distributes them across cores, combines results. Written for clarity in each language's idiomatic style.
- **Worker** (computation): The hot loops. Heap's algorithm for permutation generation, cycle counting via union-find or the Loops algorithm. Optimized aggressively — mutable arrays, zero allocation, explicit loops.

This separation is deliberate. Mathematical code should be readable at the coordination level and fast at the computation level.

### Parallelism

Work is divided into parcels by permutation prefix, then distributed across cores. Some implementations use a hand-rolled atomic work-stealing queue, some use language-native parallelism.

Benchmarks use 12 performance cores to ensure fair comparison across languages.

### Running

```
just run scala 10 3 12    # Run Scala with n=10, prefix=3, 12 cores
just do scala             # Benchmark Scala (default: 4 iterations, n=10, both algorithms)
just do                   # Benchmark all default languages
just report               # Save timing reports
just show Tarjan 10       # Display Tarjan results for n=10
```

### Key Insights

1. **Allocation in hot loops is the primary performance killer.** Top-tier performance requires eliminating allocation from the inner loops.

2. **JIT compilers gain more from algorithmic complexity.** F# and Rust tie the Tarjan crown at 100, but F# drops to 91 on Loops while Rust holds at 97 — runtime profile information helps more on the unpredictable access pattern.

3. **Simple parallel patterns work well.** A short atomic work-stealing queue is competitive with language-native parallel frameworks.

4. **The top JIT tier is readable.** F#, Kotlin, and Scala 3 deliver competitive performance with concise, expressive code.

### Conclusion

I love Ruby for scripting but it doesn't scale or perform well for math research. I've searched for compiled or typed Ruby, e.g. Crystal, and I've been left unmoved.

I'm an old Haskell programmer, coming from SML then OCaml. F# is not quite OCaml, with an impressive jit, and .NET rusty bedsprings poking through. I've been through Lisp, Scheme, Clojure, Erlang, Idris. All of these functional choices left me uncertain for various reasons.

In my dreams I only code in Lean 4. Alas, AI really struggles to use Lean as a general purpose programming language. While one might hope from Lean's design that it would be the fastest functional programming language, it is the second slowest language on my list. Lean 4 is young and under active development; I will certainly revisit this question.

My bias against Java was so extreme that I ignored Scala completely, only taking another look after being puzzled by its featured status in the Zed editor. I saw a native compiler so I gave it a try. Of course, the JVM jit is faster.

Kotlin arrived later as the obvious second JVM comparison; it runs neck-and-neck with Scala but doesn't displace it. Kotlin could be a pragmatic choice, but it is a regression in expressiveness from Scala 3 for mathematical work. Clojure also targets the JVM but landed at scores 2 and 3 across the two algorithms — ~40× slower than C++, and the only language slower than Lean 4. Way too slow to warrant consideration.

It is hard to shed prejudices about how code should look, even if learning to see clearly past convention is the only good reason to be a mathematician. I'm already quite sure how I will die: I'll read another article on Hacker News about a new programming language where I see nothing new, and I'll read that they included {}; to make C programmers comfortable. I'll have a massive stroke.

Haskell uniquely abstracts on two axes simultaneously. A single `traverse f xs` works across every traversable container — list, tree, map, custom data type — *and* every applicative effect — failure, IO, accumulation, validation. OCaml requires per-container code or explicit functor passing for each combination. Scala has the machinery via type classes, but the ceremony discourages casual use. For research code that constantly composes operations across structures-with-effects, that double-axis abstraction is the load-bearing argument for Haskell.

Scala resoundedly wins this comparison study, to my eyes. At the same time, this comparison raises the wrong questions. Especially with the advent of AI, the right question is which language supports the highest level architectural thought, and at the same time is suitable for real work. I'm the bottleneck, not my computer processing power. One could say Haskell hits that abstract-yet-practical sweet spot, and I did know this before starting this comparison project. I needed to know if there was a different answer.
