# save-version

Archives the current version of a language implementation from `source/` to `history/`.

## Synopsis

```bash
save-version <language>
```

## Description

The `save-version` command creates a versioned snapshot of a language implementation by:

1. Copying files from `source/<language>/` to `history/<language>/vN-<git-hash>/`
2. Incrementing the version number based on existing versions
3. Preserving the implementation's code and run script
4. Clearing the `timings.txt` file from the source directory

This command helps maintain a history of language implementations with their performance characteristics, preserving key development milestones.

## Arguments

* `language`: The language implementation to archive (e.g., ruby, rust, haskell)

## Examples

```bash
# Archive the current Ruby implementation
save-version ruby

# Archive the current Rust implementation
save-version rust
```

## Requirements

- Git working tree must be clean (all changes committed)
- The language must have an implementation in the `source/` directory

## Notes

- Version numbers are assigned sequentially (v1, v2, v3, etc.)
- The git hash in the directory name corresponds to the current HEAD commit
- The `timings.txt` file is removed from the source directory after archiving
- This enables consistent performance benchmarking across versions

## Related Commands

- `log-run`: Used to generate performance timings
- `clean`: Cleans build artifacts from language directories