# Clean Command

The `clean` command, implemented in Ruby, is responsible for cleaning up build artifacts in code sample directories that use our modern run command pattern. It preserves source code while removing all files that can be regenerated through compilation.

## How It Works

1. The command recursively searches through `source/` and `archive/history/` directories for `run` scripts
2. It identifies "modern" run scripts by looking for a signature comment in the first few lines:
   ```bash
   # compare-run-script: language
   ```
   where `language` specifies the programming language (e.g., `haskell`, `rust`)
   Note: The space after the colon is significant and must be handled.

3. Based on the identified language, it removes language-specific build artifacts:
   - **Haskell**: Removes `hidir`, `arm64`, `perms`, `.hi`, and `.o` files
   - **Rust**: Removes the `target` directory

4. Reports which directories were cleaned by comparing directory hashes before and after cleanup

## Implementation Notes

- Use `Pathname` for robust path handling
- Language-specific cleaners should be defined in a hash for easy extension
- File reading should be done line-by-line for efficiency
- Directory hash should consider hidden files (dotfiles)
- Relative paths should be reported by removing project root prefix
- Handle file read errors gracefully

## Example Usage

A Haskell project directory before cleaning:
```
source/haskell/example/
├── run                   # contains "# compare-run-script: haskell"
├── Main.hs               # preserved
├── hidir/                # removed
├── perms                 # removed
└── Main.hi               # removed
```

After cleaning, only `run` and `Main.hs` remain.

## Adding Support for New Languages

To add support for a new language:

1. Add a signature comment to the language's `run` script:
   ```bash
   # compare-run-script: newlang
   ```

2. Add a new cleaner to the language cleaners hash:
   ```ruby
   'newlang' => ->(dir) { FileUtils.rm_rf(Dir[File.join(dir, 'build-artifacts')]) }
   ```
