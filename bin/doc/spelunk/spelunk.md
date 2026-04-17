# Spelunk Command

The `spelunk` command helps explore the evolution of language implementations by showing sequential diffs between versions. It uses Kaleidoscope (a macOS diff tool) to compare adjacent versions of code for a specified language.

## How It Works

1. Takes a single required parameter:
   ```bash
   spelunk <language>
   ```
   where `language` is one of: haskell, rust, ruby, swift, ocaml, lean

2. Processes version directories in `archive/history/<language>/`:
   ```
   archive/history/haskell/
   ├── v1-89c1d12
   ├── v2-b15f8f5
   ├── v3-eacdf9f
   └── v4-462a619
   ```

3. Optionally performs duplicate detection (controlled by `CHECK_DUPLICATES` flag):
   - When enabled:
     - Computes SHA256 hash of each implementation file
     - If duplicates found:
       - Keeps earliest version
       - Removes later duplicates
       - Renumbers remaining versions
       - Prompts for rerun
   - Currently disabled by default

4. Opens sequential diffs in Kaleidoscope:
   - v1 → v2
   - v2 → v3
   - v3 → v4
   - etc.

## Implementation Notes

- Uses Ruby for robust file handling
- Maps languages to file extensions:
  ```ruby
  'haskell' => 'hs'
  'rust'    => 'rs'
  'ruby'    => 'rb'
  'swift'   => 'swift'
  'ocaml'   => 'ml'
  'lean'    => 'lean'
  ```
- Assumes each version directory contains `perms.<ext>`
- Preserves git commit hashes in directory names
- Requires at least 2 versions to compare

### Disabled Features

The command includes duplicate version detection (disabled by default):
- Set `CHECK_DUPLICATES = true` near top of source to enable
- Useful after bulk imports or git history scraping
- Detects and removes duplicate implementations
- Renumbers versions to maintain sequence
- Currently disabled as version history is clean

## Example Usage

```bash
# View evolution of Haskell implementation
spelunk haskell

# Clean up duplicates and renumber versions
spelunk rust  # if duplicates found, will clean up and prompt to rerun
```

Note: Requires Kaleidoscope (`ksdiff`) to be installed and accessible in PATH.
