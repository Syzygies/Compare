# Log-Run Command

The `log-run` command provides a universal wrapper for executing and timing code samples. It standardizes output formatting and timing collection across all language implementations in the project.

## How It Works

1. Takes three required parameters followed by optional flags:
   ```bash
   log-run <n> <cores> <executable> [flags...]
   ```
   - `n`: Problem size (e.g., permutation length)
   - `cores`: Number of cores to use
   - `executable`: Path to the program to run
   - `flags`: Additional arguments passed directly to the executable

2. Produces standardized output:
   ```
   === executable_name (n=N, cores=CORES) YYYY-MM-DD HH:MM ===

   /path/to/executable [flags...]

   [program output]
   
   real    0m0.123s
   user    0m0.234s
   sys     0m0.345s
   ```

## Implementation Notes

- Use `set -euo pipefail` for robust error handling
- Format timestamp using `date '+%Y-%m-%d %H:%M'`
- Preserve and display all executable flags
- Capture and show both stdout and stderr
- Show wall-clock, user, and system time via bash's `time` command
- Exit with the executable's exit code

## Example Usage

From a language-specific run script:
```bash
# Compile Haskell code...

# Run with timing using log-run
log-run "$N" "$CORES" ./perms "$N" +RTS -N"$CORES"
```

This standardization ensures that:
1. All timing data is formatted consistently
2. Run parameters are clearly documented in output
3. Timestamps enable correlation with other logs
4. Both program output and timing data are captured

## Output Handling

1. Standard output is always displayed to the console
2. For significant runs (n ≥ 9), output is appended to `timings.txt` in the implementation's root directory (where the `run` script lives):
   ```
   === executable_name (n=N, cores=CORES) YYYY-MM-DD HH:MM ===

   [program output and timing data]
   ```

This per-implementation output strategy:
- Keeps performance history with each implementation
- Localizes benchmark results alongside the source code
- Preserves results when directories are archived

## Possible Future Enhancements

1. Run Counter System
   - Could maintain an A-Z counter in `.run_counter` for each implementation
   - Would prefix each timing entry with the current letter
   - Would make it easier to reference specific runs in discussions
   - Would cycle back to A after Z

Note: Currently, each implementation directory maintains its own `timings.txt` at its root level (next to `run`), regardless of where the actual executable is built.
