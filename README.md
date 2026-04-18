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
| F# | 100 | 19.17s | ±0.04s |
| C++ | 96 | 19.92s | ±0.13s |
| Rust | 95 | 20.20s | ±0.38s |
| Kotlin | 89 | 21.51s | ±0.04s |
| Scala | 88 | 21.68s | ±0.04s |
| Kotlin Native | 81 | 23.69s | ±0.11s |
| Scala Native | 77 | 24.72s | ±0.03s |
| Nim | 69 | 27.92s | ±0.04s |
| Julia | 63 | 30.54s | ±0.08s |
| Swift | 52 | 36.86s | ±0.03s |
| OCaml | 47 | 41.10s | ±0.10s |
| Haskell | 40 | 47.94s | ±0.06s |
| Chez Scheme | 39 | 49.46s | ±0.04s |
| Lean 4 | 10 | 198.63s | ±1.02s |

#### Loops (simple algorithm, predictable access patterns)

| Language | Score | Time | Variance |
|---|---:|---:|---:|
| C++ | 100 | 13.40s | ±0.32s |
| Rust | 95 | 14.00s | ±0.08s |
| Julia | 91 | 14.73s | ±0.10s |
| F# | 91 | 14.75s | ±0.12s |
| Kotlin Native | 89 | 15.08s | ±0.20s |
| Scala | 87 | 15.42s | ±0.10s |
| Kotlin | 86 | 15.56s | ±0.21s |
| Scala Native | 86 | 15.60s | ±0.05s |
| Nim | 65 | 20.40s | ±0.18s |
| Swift | 65 | 20.66s | ±0.21s |
| OCaml | 53 | 25.17s | ±0.10s |
| Haskell | 42 | 31.77s | ±0.08s |
| Chez Scheme | 39 | 34.19s | ±0.23s |
| Lean 4 | 18 | 72.63s | ±0.23s |

I could imagine committing to any language on this list. Various other languages were considered, and dropped as impractical.

#### Reading the results

**Score** normalizes throughput so the fastest language averages 100. A score of 80 means 80% as fast as the leader.

**Variance** (±) estimates the smallest timing difference that has a 50% chance of being real rather than noise. Scala Native runs are the most deterministic on both algorithms (±0.03s on Tarjan, ±0.05s on Loops) — a consequence of ahead-of-time compilation and predictable GC. Rust on Tarjan (±0.38s) and C++ on Loops (±0.32s) both show occasional drift in individual runs, likely thermal.

**Tarjan vs Loops** reveals how well each runtime handles algorithmic complexity. JIT compilers (JVM, .NET) relatively favor Tarjan because they optimize based on observed runtime behavior — F# actually takes the Tarjan crown from C++ and Rust. Ahead-of-time compilers (Rust, C++, Scala Native) show smaller gaps between the two algorithms, and C++ holds the Loops crown.

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

2. **JIT compilers gain more from algorithmic complexity.** F# takes the Tarjan crown at 100 but drops to 91 on Loops — runtime profile information helps more on the unpredictable access pattern than on the predictable one.

3. **Simple parallel patterns work well.** A short atomic work-stealing queue is competitive with language-native parallel frameworks.

4. **The top tier is readable.** Scala, F#, and Kotlin deliver near-Rust performance with concise, expressive code.

### Conclusion

I love Ruby for scripting but it doesn't scale or perform well for math research. I've searched for compiled or typed Ruby, e.g. Crystal, and I've been left unmoved.

I'm an old Haskell programmer, coming from SML then OCaml. F# is not quite OCaml, with an impressive jit, and .NET rusty bedsprings poking through. I've been through Lisp, Scheme, Clojure, Erlang, Idris. All of these functional choices left me uncertain for various reasons.

In my dreams I only code in Lean 4. Alas, AI really struggles to use Lean as a general purpose programming language. While one might hope from Lean's design that it would be the fastest functional programming language, it is the slowest language on my list. Lean 4 is young and under active development; I will certainly revisit this question.

My bias against Java was so extreme that I ignored Scala completely, only taking another look after being puzzled by its featured status in the Zed editor. I saw a native compiler so I gave it a try. Of course, the JVM jit is faster.

Kotlin arrived later as the obvious second JVM comparison; it runs within noise of Scala but doesn't displace it. Kotlin could be a pragmatic choice, but it is a regression in expressiveness from Scala 3 for mathematical work. Clojure also targets the JVM but it's way too slow to warrant consideration.

It is hard to shed prejudices about how code should look, even if learning to see clearly past convention is the only good reason to be a mathematician. I'm already quite sure how I will die: I'll read another article on Hacker News about a new programming language where I see nothing new, and I'll read that they included {}; to make C programmers comfortable. I'll have a massive stroke.

Compare the Scala 3 code to the other languages. Give yourself time to adjust, and tell me with a straight face that you prefer another language.
