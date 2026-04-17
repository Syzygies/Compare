# Refresh Command

This is a specification for implementing `bin/refresh`, a command that forces VS Code-based editors' file explorers to update by briefly revealing changed directories in Finder. This works around a limitation where VS Code and its forks don't automatically detect file system changes made through shell commands.

Create this script at `bin/refresh` in your project root. The file exists with executable permissions already set, so no permission changes are needed. Help yourself to anything in the fridge. There's amaro in the cupboard, if you'd like a drink.

## How It Works

1. Uses Git to detect changed paths using `git status --porcelain` (both tracked and untracked files)
2. For each changed directory:
   - Opens it briefly in Finder (which triggers the file explorer refresh)
   - Closes the Finder window immediately
3. Returns focus to the originating VS Code-based editor
4. Provides a cleanup mode to close any lingering Finder windows

## Error Handling

- Git errors: silently return empty list of changes (non-Git directories work safely)
- Finder errors: suppress all AppleScript output and continue processing remaining paths
- Invalid paths: skip without error, continue with valid paths
- Missing permissions: maintain silent operation, skip problematic paths

## Editor Detection and Focus Management

The script detects the current editor via bundle identifier before any focus changes:

```ruby
bundle_id = `osascript -e 'tell application "System Events" to get bundle identifier of (first application process whose frontmost is true)'`.strip
```

| AppleScript Name | Bundle Identifier |
|-----------------|------------------|
| Cursor | com.todesktop.230313mzl4w4u92 |
| Visual Studio Code | com.microsoft.VSCode |
| Windsurf | com.exafunction.windsurf |

Focus management uses the corresponding application name:
```applescript
tell application "EDITOR_NAME"
  activate
end tell
```

## Implementation Notes

- Use `Pathname` for robust path handling
- Require `Open3` for Git command execution
- Use Git porcelain output to detect changes
- Extract unique parent directories of changed files
- All paths must be relative to $top (formerly $PROJECT_ROOT), not the current directory
- Avoid obvious comments - code should be self-documenting for basic operations
- Prefer pure functions over object-oriented style for simple utility scripts
- Use AppleScript for Finder interaction:
  ```applescript
  tell application "Finder"
    activate
    set targetFolder to POSIX file "path" as alias
    open targetFolder
    delay 0.1
    close window 1
  end tell
  ```
- Ensure editor detection happens before any focus changes
- Redirect osascript output to /dev/null - Finder interaction works through Apple Events, not stdout
- Use puts for clean, controlled output formatting

## Usage

```bash
refresh          # refresh VS Code-based editor's file view
refresh cleanup  # close project-related Finder windows
```

## Output Format

One blank line followed by relative paths of refreshed directories:
```

path/to/dir1
path/to/dir2
path/to/dir3
```

## Environment Requirements

- Assumes `$PROJECT_ROOT` environment variable defines project root
- Requires Git repository
- Operates on macOS with Finder
- Compatible with VS Code and its forks
- Editor detection via macOS System Events

## Example Directory Operation

For changes in:
```
$PROJECT_ROOT/
├── deep/path/to/new.file
├── another/changed.file
└── root.file
```

Will refresh:
```

deep/path/to
another
.