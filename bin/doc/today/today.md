# Today Script: Evolutionary Staging Directory Management

This Centaur document (serving as both human and AI prompts) describes a shell script that manages evolving staging directories. The script creates and maintains directories that serve as active workspaces until their mission is complete, then preserves them as historical record.

## Core Philosophy

### Mission-Driven Evolution
- Dates serve as convenient epochs for organizing work, not strict calendar boundaries
- A staging directory remains active until its mission is complete
- Running the script creates a new staging directory, preserving the previous one as history
- Work structure evolves organically through template inheritance

### Template as DNA
- `template.md` serves as the DNA of directory organization
- Each new staging directory inherits and can evolve this template
- Changes represent learning about better ways to structure work
- History is preserved through copying, not linking or global updates

## Core Files

### template.md - Directory Structure DNA
- Preserves and evolves preferred patterns for directory organization
- Copied forward to each new staging directory by the script
- Global in scope but maintains history through copying
- Users edit this file to evolve organizational patterns
- Must handle first-time creation gracefully
- Should provide clear initial guidance for new projects

### readme.md - Current Mission
- Documents the specific purpose(s) of this staging directory
- Created empty by the script in each new directory
- Local in scope - typically unrelated to next staging directory
- Essential first step: document the plan before starting work
- Serves as the primary reference for current work

## Workspace Integration

### Workspace File Structure
The script operates on VS Code workspace files (`.code-workspace`), which MUST follow this exact structure:
```json
{
  "folders": [
    {
      "path": "."
    }
  ],
  "settings": {
    "terminal.integrated.env.osx": {
      "top": "${workspaceFolder}",
      "bin": "${workspaceFolder}/bin",
      "now": "${workspaceFolder}/today/01-27",
      "PATH": "${workspaceFolder}/bin:${env:PATH}"
    }
  }
}
```

Key points:
- The `now` variable lives ONLY in terminal.integrated.env.osx
- There is NO separate variables section
- All paths MUST use ${workspaceFolder}
- The script updates ONLY the `now` value

### Environment Variables
- `top` and `now` are provided by workspace's terminal.integrated.env.osx section
- `now` must ALWAYS use format: "${workspaceFolder}/today/MM-DD"
- There is no separate variables section in the workspace file
- All paths are absolute using ${workspaceFolder}

### Workspace Updates
- Must locate workspace file without hardcoding name
- Must update ONLY the `now` value in terminal.integrated.env.osx
- Must handle concurrent access safely
- Must validate workspace file before and after updates

Example workspace file update:
```json
// BEFORE:
"terminal.integrated.env.osx": {
  "now": "${workspaceFolder}/today/01-26"
}

// AFTER:
"terminal.integrated.env.osx": {
  "now": "${workspaceFolder}/today/01-27"
}
```

### Workspace Updates
- Must locate workspace file without hardcoding name
- Must update `now` variable safely with proper path construction
- Must handle concurrent access safely
- Must validate workspace file before and after updates

## Core Functionality

1. First-Time Setup:
   - Create initial staging directory if none exists
   - Create starter template.md with useful defaults:
     ```markdown
     # Directory Structure Template
     
     This template guides the organization of our staging directories.
     Edit this file to evolve our practices, and it will be carried forward.
     
     ## Common Patterns
     - context/ - For background and planning documents
     - research/ - For investigation and learning
     - implementation/ - For actual code changes
     ```
   - Initialize workspace variables if needed
   - Provide clear guidance for new users

2. Normal Operation:
   - Create new staging directory (today/MM-DD/)
   - Copy template.md forward from previous directory
     - Must preserve file timestamps
     - Must handle missing source gracefully
     - Must validate successful copy
   - Create empty readme.md for new mission
   - Update workspace's `now` variable
   - Preserve previous staging directory as history

3. Path Construction:
   - ALL paths must use ${workspaceFolder}:
     ```bash
     # CORRECT:
     now="${workspaceFolder}/today/01-27"
     
     # INCORRECT:
     now="today/01-27"  # Missing ${workspaceFolder}
     now="/full/path/to/today/01-27"  # Hardcoded full path
     ```
   - Environment variables store paths relative to workspace:
     ```json
     "now": "today/01-27"  # Relative to ${workspaceFolder}
     ```
   - Script must combine them correctly:
     ```bash
     PREV_DIR="${workspaceFolder}/${now}"  # Combine for full path
     ```

4. Workspace File Handling:
   - Must find workspace file without hardcoding:
     ```bash
     # Search up from current directory for .code-workspace
     find_workspace() {
       local dir="$1"
       while [[ "$dir" != "/" ]]; do
         local workspace_file=$(find "$dir" -maxdepth 1 -name "*.code-workspace" | head -n1)
         [[ -n "$workspace_file" ]] && echo "$workspace_file" && return 0
         dir="$(dirname "$dir")"
       done
       return 1
     }
     ```
   - Must validate workspace file structure:
     ```bash
     # Verify workspace file has correct structure
     validate_workspace() {
       local file="$1"
       if ! grep -q '"terminal.integrated.env.osx"' "$file"; then
         echo "Error: Workspace file missing terminal.integrated.env.osx section"
         return 1
       fi
       # Add more validation as needed
     }
     ```
   - Must update workspace safely:
     ```bash
     # SAFE - Use sed for atomic update of now variable
     update_workspace() {
       local file="$1"
       local new_date="$2"
       local temp_file="${file}.tmp"
       local backup_file="${file}.bak"
       
       # Create backup
       cp "$file" "$backup_file"
       
       # Update now variable, preserving structure
       sed -E "s|(\"now\":[[:space:]]*\"\\$\{workspaceFolder\}/today/)[^\"]+|\1${new_date}|" \
         "$file" > "$temp_file" && mv "$temp_file" "$file"
       
       # Verify update
       if ! grep -q "\"now\": \"\${workspaceFolder}/today/${new_date}\"" "$file"; then
         echo "Error: Failed to update workspace file"
         mv "$backup_file" "$file"
         return 1
       fi
     }
     ```

5. Error Prevention:
   - Validate all paths before operations
   - Check file permissions early
   - Verify workspace file integrity
   - Handle concurrent access safely
   - Provide clear, actionable error messages

## Requirements

### Safety & Boundaries
- All operations contained within today/ for predictability
- Preserve existing files (idempotent operation)
- Create missing directories as needed
- Run silently unless there's an error
- Fail fast with clear, actionable error messages
- Handle concurrent access safely

### Technical Requirements
- Must work on macOS (BSD userland, no GNU extensions)
- Must work from any directory (uses `top` for project root)
- Must maintain workspace environment variables
- Must use set -euo pipefail
- Must handle paths with spaces and special chars correctly
- Must support both new projects and migrations

### Error Handling
- Each error message must be actionable
- Must indicate what went wrong
- Must suggest how to fix it
- Must handle all first-time setup cases
- Must validate workspace updates
- Must check permissions before operations

## Example Tree

Input:
```
today/
├── 01-26/                   [active staging directory]
│   ├── readme.md             [current mission details]
│   ├── template.md           [current DNA snapshot]
│   └── task-name/           [task-specific folder]
└── 01-27/                   [new staging directory]
```

Output:
```
today/
├── 01-26/                   [preserved as history]
│   ├── readme.md            [archived mission]
│   ├── template.md          [preserved DNA snapshot]
│   └── task-name/          [preserved work]
└── 01-27/
    ├── readme.md           [empty, awaiting intent]
    └── template.md         [evolved from 01-26]
```

## Migration Support

For projects migrating from archive-based to staging-based structure:
1. Script detects legacy archive/YYYY/MM-DD structure
2. Offers to migrate latest work to today/MM-DD
3. Preserves old archive structure as history
4. Creates new template.md based on existing patterns

## Test Cases
1. First-time setup: ./today in new project
2. Normal operation: cd /tmp && /path/to/bin/today
3. Special characters: mkdir -p "today/01-26/task with spaces/"
4. Idempotency: ./today && ./today
5. Migration: Convert from archive/ to today/
6. Concurrent access: Run multiple instances
7. Workspace updates: Verify `now` variable handling
8. Error cases: Test all error messages

## Why This Matters
This script enables evolutionary workspace management where:
1. Structure evolves to match changing needs
2. History is preserved but not constraining
3. Each staging directory serves a clear mission
4. Templates guide without restricting
5. Integration with IDE enhances workflow

The template-based evolution allows practices to grow organically while maintaining
consistency across work sessions. This balance of flexibility and structure
supports both individual and team workflows effectively.

## History

Major changes and their context:

### January 28, 2025 - Template-Based Evolution
- Moved from hard-coded structure to template-based evolution
- Simplified directory structure (removed year layer)
- Made script idempotent
- Full context: `today/01-27/update-today-command/`

Previous versions are in `versions/`. This history section tracks significant changes and links to their full context in daily work folders.
