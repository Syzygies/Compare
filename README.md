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
| Rust | 100 | 19.78s | ±0.03s |
| C++ | 99 | 20.03s | ±0.30s |
| F# | 95 | 20.81s | ±0.09s |
| Scala | 91 | 21.84s | ±0.04s |
| Kotlin | 88 | 22.48s | ±0.14s |
| Scala Native | 77 | 25.79s | ±0.09s |
| Nim | 76 | 26.06s | ±0.03s |
| Julia | 65 | 30.54s | ±0.06s |
| Swift | 60 | 33.10s | ±0.09s |
| OCaml | 48 | 40.94s | ±0.03s |
| Haskell | 42 | 47.48s | ±0.05s |
| Chez Scheme | 40 | 49.22s | ±0.07s |
| Lean 4 | 10 | 198.63s | ±1.02s |

#### Loops (simple algorithm, predictable access patterns)

| Language | Score | Time | Variance |
|---|---:|---:|---:|
| Rust | 100 | 13.11s | ±0.03s |
| C++ | 100 | 13.16s | ±0.12s |
| Julia | 90 | 14.50s | ±0.01s |
| F# | 82 | 15.89s | ±0.03s |
| Kotlin | 79 | 16.54s | ±0.12s |
| Scala | 78 | 16.80s | ±0.08s |
| Scala Native | 76 | 17.32s | ±0.10s |
| Nim | 74 | 17.79s | ±0.02s |
| Swift | 65 | 20.26s | ±0.02s |
| OCaml | 52 | 25.03s | ±0.02s |
| Haskell | 41 | 31.68s | ±0.01s |
| Chez Scheme | 38 | 34.32s | ±0.08s |
| Lean 4 | 18 | 72.63s | ±0.23s |

I could imagine committing to any language on this list. Various other languages were considered, and dropped as impractical.

#### Reading the results

**Score** normalizes throughput so the fastest language averages 100. A score of 80 means 80% as fast as the leader.

**Variance** (±) estimates the smallest timing difference that has a 50% chance of being real rather than noise. Low variance means consistent performance. C++ shows the most jitter; Haskell and Julia are the most deterministic.

**Tarjan vs Loops** reveals how well each runtime handles algorithmic complexity. JIT compilers (JVM, .NET) gain a larger advantage on Tarjan because they optimize based on observed runtime behavior. Ahead-of-time compilers (Rust, C++, Scala Native) show less difference between the two algorithms.

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
just do scala 4x 10       # Benchmark: 4 iterations, both algorithms, n=10
just report               # Save timing reports
just show Tarjan 10       # Display Tarjan results for n=10
```

### Key Insights

1. **Allocation in hot loops is the primary performance killer.** Top-tier performance requires eliminating allocation from the inner loops.

2. **JIT compilers gain more from algorithmic complexity.** Scala JVM scores 91 on Tarjan but 78 on Loops — a wider gap than ahead-of-time compilers show between the two algorithms.

3. **Simple parallel patterns work well.** A short atomic work-stealing queue is competitive with language-native parallel frameworks.

4. **The top tier is readable.** Scala, F#, and Kotlin deliver near-Rust performance with concise, expressive code.

### Conclusion

I love Ruby for scripting but it doesn't scale or perform well for math research. I've searched for compiled or typed Ruby, e.g. Crystal, and I've been left unmoved.

I'm an old Haskell programmer, coming from SML then OCaml. F# is not quite OCaml, with an impressive jit, and .NET rusty bedsprings poking through. I've been through Lisp, Scheme, Clojure, Erlang, Idris. All of these functional choices left me uncertain for various reasons.

In my dreams I only code in Lean 4. Alas, AI really struggles to use Lean as a general purpose programming language. While one might hope from Lean's design that it would be the fastest functional programming language, it is the slowest language on my list. Lean 4 is young and under active development; I will certainly revisit this question.

My bias against Java was so extreme that I ignored Scala completely, only taking another look after being puzzled by its featured status in the Zed editor. I saw a native compiler so I gave it a try. Of course, the JVM jit is faster.

Kotlin arrived later as the obvious second JVM comparison; it runs within noise of Scala but doesn't displace it. Kotlin could be a pragmatic choice, but it is a regression in expressiveness from Scala 3 for mathematical work.

It is hard to shed prejudices about how code should look, even if learning to see clearly past convention is the only good reason to be a mathematician. I'm already quite sure how I will die: I'll read another article on Hacker News about a new programming language where I see nothing new, and I'll read that they included {}; to make C programmers comfortable. I'll have a massive stroke.

Compare the Scala 3 code to the other languages. Give yourself time to adjust, and tell me with a straight face that you'd rather code in any other language.

(That's after accepting the one whopper I simply can't believe: "for" in a hot loop allocates a range object, and Scala Native doesn't optimize this away. This crashed the garbage collector. I had to write out tedious while statements, like I was back in my high school library using a paperclip to enter my first BASIC program into punched cards.)
