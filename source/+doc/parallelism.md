# GHC Parallel Strategy Implementation Guide

This document describes the GHC parallelism approach used in the Lattices project, designed to be dropped into other Haskell projects for adaptation.

## Required GHC Compiler Options

The following compiler flags are essential for enabling parallelism:

```bash
-threaded      # Enable multi-threaded runtime system
-rtsopts       # Allow runtime system options to be set at execution
```

Additional recommended optimizations:
```bash
-O2                     # Enable optimizations
-funbox-strict-fields   # Unbox strict fields for performance
```

## Runtime Execution

Execute the program with runtime options to specify the number of cores:

```bash
./executable +RTS -N<cores>
```

Where `<cores>` is the number of processor cores to use. On macOS with Apple Silicon, you can detect performance cores using:

```bash
sysctl -n hw.perflevel0.physicalcpu
```

## Sparks and Workers Approach

The parallelism strategy uses GHC's lightweight sparks to create work units that can be executed in parallel by worker threads.

### Key Components

1. **Spark Creation**: Use `par` to create sparks (potential parallel computations)
2. **Evaluation Control**: Use `pseq` to control evaluation order
3. **Chunking Strategy**: Divide work into appropriately sized batches
4. **Worker Distribution**: Let the runtime system distribute sparks to available cores

### Core Implementation Pattern

```haskell
import Control.Parallel (par, pseq)

-- Basic parallel evaluation
x `par` y `pseq` result
-- Creates a spark for x, evaluates y, then returns result

-- Multiple spark creation
pars :: [a] -> b -> b
pars [] y = y
pars (x:xs) y = x `par` pars xs y

-- Batch processing with configurable parameters
nbatch = 1024  -- Batch size for chunking work
nspark = 32    -- Number of initial sparks to create
```

### FG Pattern (Fork-Gather)

The project uses an FG (Fork-Gather) pattern for parallel map-reduce operations:

```haskell
data FG a b = FG ([a] -> b) ([b] -> b)
-- FG f g: apply f to sublists, combine results using g

-- Example usage:
-- parFG (FG processChunk combineResults) inputList
```

### Chunking and Spark Management

1. **Chunk the input** into manageable pieces (e.g., 1024 elements)
2. **Create initial sparks** for parallel processing (e.g., 32 sparks)
3. **Self-replicating spark batches** for continuous work distribution
4. **Yield results** while creating new sparks

### Performance Considerations

- Use `pseq` to ensure proper evaluation order (5% speedup observed)
- Chunk size affects granularity - too small creates overhead, too large reduces parallelism
- Initial spark count should roughly match available cores
- Self-replicating spark batches help maintain work distribution

## Integration Steps

1. Add the compiler flags to your build configuration
2. Import `Control.Parallel`
3. Identify computationally intensive list operations
4. Apply chunking and spark creation patterns
5. Use FG pattern for map-reduce style parallelism
6. Run with appropriate `-N` runtime flag

## Example Adaptation

For a compute-intensive function over a list:

```haskell
-- Sequential version
result = map expensiveFunction largeList

-- Parallel version
result = parFG (FG expensiveFunction concat) largeList
```

This approach provides efficient parallelism with minimal code changes while leveraging GHC's sophisticated runtime system for work distribution.