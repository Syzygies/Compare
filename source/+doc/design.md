# Project Design Document

## 1. Philosophy

This project implements a non-trivial algorithm (cycle distributions of hyperoctahedral group elements) to evaluate programming languages for mathematical research. The implementation follows a strict dichotomy:

**High-level code (Perms module)**: Prioritize clarity and idiomatic style. Use functional patterns where natural. Performance is irrelevant here - this code coordinates work, not computation.

**Hot loops (Worker module)**: Optimize aggressively. Every allocation matters. Pre-allocate and reuse all data structures. Use mutable state freely. The goal is maximum performance while maintaining correctness.

**Memory allocation strategy**: Allocate once per parcel, not per thread. For n=10, prefix=3, cores=12, this means 720 allocations (one per prefix) spread across ~30 seconds of wall time - about one allocation every 40ms per core. This is negligible overhead while keeping code clean and simple. Any AI suggesting "optimization" by allocating per thread instead of per parcel has misunderstood the design and should re-read this section.

## 2. Specification

This document outlines the complete specification for the "perms" project, a benchmark for enumerating the cycle distributions of signed permutations (elements of the hyperoctahedral group, B_n).

As a guiding principle, when this specification is unclear or ambiguous, developers should first examine the working implementations in other languages for precedent. If the ambiguity persists, it should be resolved by asking the project lead.

### 2.1. Core Requirements

All language implementations must conform to the following requirements to ensure a fair and accurate comparison. **Scala and OCaml serve as the reference implementations.**

1.  **Problem Domain**: For a given integer `n`, the program must calculate the distribution of cycle counts for all `n! * 2^n` signed permutations. The output is an array where the value at index `k` is the number of signed permutations that decompose into `2n - k` cycles.

2.  **Work Distribution**: The total work must be partitioned into parcels based on a permutation prefix of length `prefix`. The program generates all `P(n, prefix)` prefixes, and each prefix defines a parcel of work. No other partitioning or sub-division of work is permitted.

3.  **Parallelism**: Test both a custom atomic queue (see OCaml's Parallel module) and the language's best native parallel construct. Keep whichever is faster. The `cores` parameter must be accepted for interface consistency, but languages with runtime-managed parallelism (e.g., Haskell with +RTS -N) may handle it externally via the run script. Each worker processes complete parcels (prefixes) atomically.

4.  **Dual Algorithms**: Each implementation must provide two distinct cycle-counting algorithms: **Tarjan's union-find** and the **Loops** algorithm.

5.  **Algorithm Switching**: The choice between `Tarjan` and `Loops` must be selectable with **zero runtime overhead**. The selection follows a strict pattern for `bin/switch-algorithm` compatibility: a comment line containing "Select Tarjan or Loops" followed immediately by code containing either "Tarjan" or "Loops". Approaches:
    * **Source-level switching** (preferred): A line in the source file matching:
        ```
        <keyword> <variable> = [Loops|Tarjan] <comment_start> Select Tarjan or Loops
        ```
        Examples:
        * Rust: `type Relations = Loops; // Select Tarjan or Loops`
        * OCaml: `module Sets = Loops (* Select Tarjan or Loops *)`
        * Swift: `typealias Relations = Loops // Select Tarjan or Loops`
        * F#: `module Sets = Loops // Select Tarjan or Loops`
        * Haskell: `type Relations = Tarjan.Relations -- Select Tarjan or Loops`
        * Scala: comment on line before, then `type Relations = Tarjan; val name = "Tarjan"` on next line
        * Kotlin: comment on line before, then `typealias Relations = Tarjan` on next line
        
        **Note**: When using the Worker module pattern, the algorithm selection line typically appears in the Worker module rather than the main module, since that's where the algorithm is actually used.
    * **Build-script switching**: Selection in the build/run script, provided the script contains the same pattern comment for automated switching

6.  **Hot-Loop Performance**: Zero allocations in hot loops. Pre-allocate Relations and tally arrays once per parcel (not per thread). Inside the loops processing millions of permutations, allocation is forbidden.

7.  **Answer Data for Validation**: Each implementation must include a data structure containing the known correct results for `n`=1 through `n`=12. This enables the program to perform self-validation upon completion. Note that for `n`≥11, some values exceed 32-bit integer limits and require 64-bit integers. In practice, this data structure can be copied from an existing, working implementation.

8.  **Naming Consistency**: Use identical names across all languages, adjusting only for language conventions (runPrefix vs run_prefix). Never rename without strong justification (e.g., avoiding reserved words).

9.  **Code Comments**: Comments serve as section titles for blocks of code. Avoid changelog-style comments, excessive explanation, or "what I just did" markers. See OCaml implementation for preferred style.

### 2.2. Input and Output

* **Input**: The program accepts three command-line arguments: `n` (1-12), `prefix` (0-n), and `cores` (>=1).

* **Output**: The program's standard output must strictly follow this format:
    1.  **Header Line**: A single line: `{Algorithm} v{version}, n = {n}, prefix = {prefix}, cores = {cores}`
    2.  **Result Line**: A single line containing the result array as space-separated integers with no other punctuation.
    3.  **Validation Line(s)**:
        * **Correct**: A single checkmark `✓` on a new line.
        * **Incorrect**: A single `✗` on a new line, followed by another new line containing the expected answer, formatted as space-separated integers with no other punctuation.
        * **Unknown**: A single `?` on a new line if `n > 12`.

    **Example of Correct Output (n=6):**
    ```
    Loops v1, n = 6, prefix = 2, cores = 12
    1 6 45 170 655 1666 3991 6790 10124 10568 8224 3840
    ✓
    ```

    **Example of Incorrect Output (n=6):**
    ```
    Loops v1, n = 6, prefix = 2, cores = 12
    2 6 45 170 655 1666 3991 6790 10124 10568 8224 3840
    ✗
    1 6 45 170 655 1666 3991 6790 10124 10568 8224 3840
    ```

## 3. Algorithm Tutorials

A deep understanding of the two cycle-counting algorithms is critical for a correct implementation. Both operate on a graph of `2n` vertices.

### 3.1. Tarjan's Union-Find Algorithm

Tarjan's algorithm is a general-purpose method for finding the connected components of a graph, which in this problem corresponds to the number of cycles.

* **Concept**: It maintains a forest of trees, where each tree represents a set of connected elements. A single array `root` (or `parent`) stores the parent of each element.
* **Initialization**: Each of the `2n` elements starts as its own root (`root[i] = i`). The initial number of sets is `2n`.
* **`find(a)` Operation**: To find the "true" root of element `a`'s set, we traverse up the parent pointers until we find an element that is its own parent.
    * **Path Compression (Crucial Optimization)**: After finding the ultimate root, we re-traverse the path from `a` to the root and set the parent of every element along that path directly to the root. This flattens the tree, making future `find` operations on any of those elements extremely fast (nearly constant time). Implementations typically use either recursive or iterative (two-pass) path compression.
* **`unite(a, b)` Operation**:
    1.  Find the roots of `a` and `b`, let's call them `a_root` and `b_root`.
    2.  If they are already the same, `a` and `b` are already in the same set, so do nothing.
    3.  If they are different, connect them by setting `root[a_root] = b_root`.
    4.  Decrement the total number of sets.
    
    **Note on Union-by-Size**: The traditional Tarjan algorithm uses "union by size" to keep trees shallow by always attaching the smaller tree to the larger one. However, for this specific benchmark with small set sizes (max 24 elements), empirical testing showed that the branch misprediction cost of the size comparison outweighs its benefits. All implementations have been optimized to use the simpler approach of always attaching the first root to the second.
* **Result**: After all relations are processed, the final value of the `sets` counter is the number of cycles.

### 3.2. The Loops Algorithm

The Loops algorithm is a specialized, highly efficient method for finding cycles in a graph composed of disjoint paths and cycles (a permutation graph).

* **Concept**: It uses a single array, `ends`, to track the two endpoints of every path. It does not need a `size` array or path compression.
* **Initialization**: The `ends` array of size `2n` is initialized so that every element is its own endpoint (`ends[i] = i`). This represents `2n` paths of length one. The cycle count is zero.
* **`unite(a, b)` Operation**: This is the core of the algorithm.
    1.  Get the current endpoints: `ea = ends[a]` and `eb = ends[b]`.
    2.  **Crucial Check**: If `ea == b`, it means we are trying to connect the end of a path to its beginning. A cycle has just been formed. The algorithm increments the `sets` (cycle) counter and does nothing else.
    3.  **Path Merging**: If `ea != b`, it means `a` and `b` are on different paths. The algorithm merges them by swapping their endpoints: `ends[ea] = eb` and `ends[eb] = ea`. What were two separate paths are now one long path with two new endpoints.
* **Result**: After all relations are processed, the final value of the `sets` counter is the number of cycles.

## 4. Implementation Guide for New Languages

When implementing in a new language, follow these key patterns that have proven successful across all existing implementations:

### 4.1. Module Organization

**Worker Module Pattern**: Separate hot-loop code into a dedicated Worker module:
- Main module (Perms): Argument parsing, parallelism, result aggregation - idiomatic/functional style
- Worker module: `runPrefix`, `tallyPerms`, `countCycles`, `tallySigns` - optimized for performance
- Algorithm modules (Tarjan/Loops): Implement `create`, `reset`, `unite`, `count` with identical interface
- Parallel module: Reusable parallelism abstraction, either custom atomic queue or best native approach

**Function Naming**: Keep names identical across languages (adjusting only for conventions: `run_prefix` vs `runPrefix`).

### 4.2. Critical Implementation Details

**Parallel Module**: Test custom atomic queue (see OCaml) against best native parallelism. Keep whichever is faster. Accept `cores` parameter for consistency even if managed externally (e.g., Haskell's +RTS).

**Algorithm Selection**: Zero runtime cost required. Use type/module aliasing controlled by `bin/switch-algorithm`. Pattern: comment with "Select Tarjan or Loops" followed by line containing the algorithm name.

**Hot Loop Optimization**: 
- Apply language-specific optimizations to Worker module only (e.g., Haskell's `{-# LANGUAGE Strict #-}`)
- Mutable internally, immutable externally (e.g., Haskell's ST monad, OCaml's arrays)
- Zero allocations inside loops - pre-allocate everything per parcel

**Reset via seed + copy**: `reset` runs once per permutation (billions of calls at n=10). Consider block-copying from a pre-built `seed` array instead of a scalar `root[i] = i` loop. The win depends on both the runtime and the surrounding hot loop:
- **Clear win**: JVM (Scala, Kotlin) via `System.arraycopy`, .NET (F#) via `Array.blit`/`Array.Copy`, Scala Native and Kotlin/Native via LLVM `memcpy`. These runtimes otherwise can't vectorize through safepoints, bounds checks, or GC write barriers; the intrinsic bypasses all that.
- **Algorithm-dependent**: Rust gained ~4.4% on Tarjan (taking top score) but lost ~3% on Loops — `find`'s register-pressure profile benefits from the shorter emitted code, while `unite` was already near-ideal. Keep Rust Tarjan on seed+copy; Rust Loops stays scalar.
- **No win**: C++ (`std::copy_n`) regressed ~4% on Loops and held flat on Tarjan. AOT LLVM at `-O3` already emits optimal vectorized code for the scalar loop, so the seed adds a useless load.
- **Regression**: OCaml's `Array.blit` is a regular library function; call overhead dominates at n=20.

Worth trying for any new language and for each algorithm; measure both before committing.

**swap Function**: Define where optimal for inlining (usually Worker module). Export if needed by Perms.

### 4.3. Common Implementation Pitfalls

1. **Path Compression Bug**: In Tarjan's algorithm, failing to implement path compression correctly causes exponential slowdown for larger n.

2. **Reset vs Create**: The `reset` function is called repeatedly in the hot loop. Ensure it's efficient and doesn't unnecessarily re-initialize already-correct values.

3. **Off-by-One Errors**: The mapping between permutation elements and union-find vertices requires careful indexing.

4. **Race Conditions**: Work distribution and result aggregation must be properly synchronized.

5. **Sign Bit Handling**: The bitwise operations for sign patterns must be implemented correctly (typically using shift and mask operations).

## 5. Build System Requirements

### 5.1. Standard Runner Script

Each implementation must provide a `run` script that:
1. Compiles the code with maximum optimizations
2. Executes the program with provided arguments
3. Returns the program's exit code

**Important**: Copy and adapt an existing `run` script from another language implementation. All scripts follow the same pattern:
- Change to the source directory with `cd "$(dirname "$0")"`
- Get repository root with `git rev-parse --show-toplevel`
- Build the program with appropriate optimization flags
- Execute via `"$top/bin/log-run" ./your-binary $n $prefix $cores`

### 5.2. Algorithm Switching Script

The `bin/switch-algorithm` script must be able to modify your source to switch between Tarjan and Loops. Ensure your switching line follows the specified pattern exactly. 

**Worker Module Note**: If you implement the Worker module pattern, ensure that `bin/switch-algorithm` includes your Worker module file in its file list. The algorithm selection line should appear in whichever module actually uses the algorithm (typically the Worker module).

## 6. Validation and Testing

### 6.1. Correctness Validation

1. **Self-Test**: Every implementation must validate its output against the known correct answers for n=1 through n=12. The answers array should be copied from a working implementation.

2. **Test Cases**: Start with small values (n=3, prefix=1, cores=1) to verify correctness before scaling up.

3. **Algorithm Consistency**: Both Tarjan and Loops must produce identical results for all inputs.

### 6.2. Testing Approach

1. Start with n=3, verify output matches expected: `1 3 9 13 14 8`
2. Test both algorithms produce identical results
3. Test with different prefix values (0 to n)
4. Scale up gradually to n=10 (the standard benchmark size)

This specification provides all requirements for implementing the cycle distribution benchmark in a new language. For any ambiguities, consult existing implementations or contact the project lead.

## 7. Current Status

Benchmarked on Apple M4 Max (12 performance cores) at n=10, 4 iterations per run. Rankings shift as optimizations land; see `timings/` for the latest full report.

Top tier (Tarjan score, 04-18 1316):
- **F#**: 100 — .NET JIT intrinsifies `Array.Copy`; takes the Tarjan crown
- **C++**: 96 — fast but verbose
- **Rust**: 95 — peak performance, ceremony can obscure mathematics
- **Kotlin**: 89 (JVM) / 81 (Native) — JVM peer to Scala
- **Scala**: 88 (JVM) / 77 (Native) — strong readability + performance balance

Mid tier:
- **Nim**: 69
- **Julia**: 63
- **Swift**: 52

Lower tier:
- **OCaml**: 47 — syntactic pleasure offsets the performance gap for some tasks
- **Haskell**: 40
- **Chez Scheme**: 39
- **Lean 4**: 10 — young language under active development; will revisit

Rejected:
- **Clojure**: too slow to warrant consideration (JVM, but emitted bytecode is not competitive)

### Key Insights
1. **Allocation in hot loops is the primary performance killer** — use while loops in hot paths to avoid Range allocation overhead in Scala
2. **JIT compilers gain more from algorithmic complexity** — F# takes the Tarjan crown at 100 but drops to 91 on Loops, and Scala/Kotlin show the same shape. Runtime profile information helps more on Tarjan's unpredictable access pattern than on Loops' already-predictable one; AOT compilers (C++, Rust, Scala Native) show smaller Tarjan-vs-Loops gaps
3. **Scala Native crashes if `for` loops trigger GC** — the `for` Range allocation triggers garbage collection, and worker threads in tight while loops can't reach GC safepoints, causing a fatal timeout
4. **The sweet spot exists** — Scala 3 and Kotlin deliver near-Rust performance with concise, expressive code
5. **Reset-via-seed-copy** (see §4.2) is a cross-cutting optimization that paid off in every language with an intrinsified copy; measurable win only in the hot-loop regime

## 8. Working with This Project

- `just run <language> [n] [prefix] [cores]` — single run
- `just do [languages...] [4x|x4] [tarjan|loops] [n [prefix [cores]]]` — benchmark harness; defaults to 4 iterations at n=10, both algorithms, across the tier-1 default language set. Arguments are space-separated. `4x` or `x4` sets iterations; bare numbers set n / prefix / cores in that order; `tarjan`/`loops` (or `t`/`l`) restricts to one algorithm. Override cooldown with `COOLDOWN=<seconds>` (default 10).
- `just report` — save fresh Tarjan + Loops timing reports into `timings/`; silent on success
- `just show <algorithm> [n]` — display a report
- `just scrape <language-prefix>` — collect historical rows for a language prefix across all `timings/*.txt`
- `just format [lang]` — format source (scalafmt for Scala, language-specific otherwise)
- `bin/switch-algorithm Tarjan` / `bin/switch-algorithm Loops` — switch all implementations
- Performance data logged to `timings/data/{hostname}.csv`

## 9. Language-Specific Notes

### Scala
- Builds both JVM and Native from `source/scala/`
- Toggle JVM/Native in `source/scala/run` by commenting `jvm=true` or `native=true`
- Native runs via `source/scala/scala-native/run` internally
- Use `while` loops in Worker hot paths — `for` allocates Range objects and (on Native) can trigger fatal GC stalls
- Format with `just format` (scalafmt, config in `.scalafmt.conf`)
- IDE support via Metals; run `scala-cli setup-ide src/` if needed
- Scala Native is the primary optimization target: **never degrade native for JVM**

### Kotlin
- Builds both JVM and Kotlin/Native from `source/kotlin/`
- Toggle native in `source/kotlin/run` via `native=true`
- Native lives at `source/kotlin/kotlin-native/` as a sibling subdirectory to the JVM source
- Worker-API warnings in `kotlin-native/Parallel.kt` are suppressed with `@file:OptIn(kotlin.native.concurrent.ObsoleteWorkersApi::class)`
- JVM-side warnings are suppressed via `JAVA_OPTS="--enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow"`

### Haskell
- Uses modern Cabal v2 via GHCup with project-local builds
- Build: `just run haskell` or `cabal build`
- Dependencies in `dist-newstyle/`; shared package cache in `~/.cabal/store/`
- Never use v1-style commands or global installs

## 10. Algorithm Selection Pattern

The `bin/switch-algorithm` script rewrites the line *following* a comment that contains the literal phrase **"Select Tarjan or Loops"**. That next line must contain either the token `Tarjan` or the token `Loops`, which the script rewrites to the chosen algorithm.

Per-language examples:
- **Rust**: `type Relations = Loops; // Select Tarjan or Loops`
- **OCaml**: `module Sets = Loops (* Select Tarjan or Loops *)`
- **Swift**: `typealias Relations = Loops // Select Tarjan or Loops`
- **F#**: `module Sets = Loops // Select Tarjan or Loops`
- **Haskell**: `type Relations = Tarjan.Relations -- Select Tarjan or Loops`
- **Scala**: comment on line before, then `type Relations = Tarjan; val name = "Tarjan"` on the next line
- **Kotlin**: comment on line before, then `typealias Relations = Tarjan` on the next line

When using the Worker module pattern, the selection line typically lives in the Worker module, since that's where the algorithm is used.

## 11. Naming as Poetry: Worked Examples

This project has refined three names worth studying:

- **`seed`** — the identity permutation we copy from to reset the union-find state. Evokes growing fresh state from an unchanging source. Four chars, one syllable, reads the way the code behaves.
- **`here`** — the walking cursor in Tarjan's `find`. Reads as English: `while root(here) != here do here = root(here)`. Replaces the crumbled `current` / `cur`.
- **`top`** — the fixed point at the end of a parent chain, used where naming the local `root` would visually collide with the `t.root` field (OCaml, F#). Even though OCaml requires field qualification and thus cannot shadow, `top` avoids the reader's momentary double-take. Scala's mandatory `this` qualification makes shadowing a real hazard, so Scala uses `r` locally for the same reason expressed more tersely.

And a layout observation: in `source/scala/src/Tarjan.scala` lines 4-6, `seed`/`root`/`sets` are all 4 chars and the `=` column falls into place without any manual alignment — a bonus of naming discipline, not an invitation to pad with spaces.