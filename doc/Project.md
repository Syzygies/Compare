# Language Performance Comparison Project

## Current Status (As of April 2025)

### Recent Reorganization
1. Migration from `PROJECT_ROOT` to `$top` environment variable (completed)
2. Modernization of run scripts (in progress)
3. Directory structure reorganization (in progress)
   - Goal: Each version in history should be a complete, self-contained experiment
   - Local timing results should be preserved with each implementation

### Run Script Modernization
- Modern run scripts now use the format: `# compare-run-script: {language}`
- Scripts use `log-run` for consistent timing output
- Each language directory should contain its own run script and local timings.txt
- Status:
  - ✓ Haskell, Lean: Modern run scripts implemented
  - ✓ Ruby, OCaml, Swift, Rust: Run scripts created but need testing

### Implementation Status
- All language implementations are complete and working
- Current focus is on modernizing tooling and ensuring consistent experiment structure
- Rust implementation may need dependency fixes for rayon library

## Historical Context

We maintain explicit version history beyond git because:
1. Performance evolution needs context git doesn't naturally provide
2. Key implementation changes should be preserved with their timing results
3. Comparing across time requires stable reference points

Each historical version preserves:
- Source code snapshot
- Timing results
- Implementation approach

## Analysis Principles

1. **Cross-Language Comparison**
   - Consistent implementation across languages
   - Standardized timing methodology
   - Fair comparison of language features and performance

2. **Performance Insights**
   - Document why optimization attempts succeeded or failed
   - Preserve insights about language-specific performance characteristics
   - Track how implementation strategy affects performance

3. **Workflow Optimization**
   - Prototype in higher-level languages (Ruby)
   - Translate to performance-oriented languages (Rust)
   - Use AI assistance for translation and mechanical tasks

## Next Steps

1. **Test Run Scripts**:
   - Run each newly created script to verify it works correctly
   - Test on older versions to ensure compatibility

2. **Complete Reorganization**:
   - Finish directory restructuring
   - Update workspace definitions accordingly

3. **Performance Testing**:
   - Run comparative benchmarks on M4 Max Mac Studio
   - Update timings and document hardware differences

## Current Focus
- Comparing language performance for permutation generation
- Analyzing single-core vs multi-core scaling
- Understanding memory usage patterns
- Implementing consistent timing methodology across languages