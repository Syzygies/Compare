# Context Script Specification

This is a specification for implementing a script that finds and outputs potential context files from the project directory.

## Implementation Location

Create this script at `$bin/context`

## Purpose

The script scans the project directory for files that could provide useful context:
- All markdown (*.md) files
- Any executable files that begin with a shebang (#!)

It outputs the paths of these files relative to the project root ($top).

## Usage

```bash
context              # List all potential context files, one per line
context --annotated  # Prefix each line with @ symbol
```

## Output Format

### Default Output
Paths relative to project root, one per line:
```
bin/today
bin/doc/guidelines.md
bin/doc/today/today.md
```

### Annotated Output (--annotated)
Same paths but prefixed with @:
```
@bin/today
@bin/doc/guidelines.md
@bin/doc/today/today.md
```

## Implementation Requirements

- Use Ruby for implementation
- Search recursively from project root
- Skip version control directories (.git)
- For executables, only include those with shebang lines
- Output should be sorted alphabetically
- Paths should use forward slashes
- No trailing whitespace in output

## Error Handling

- Exit with status 1 if project root cannot be determined
- Exit with status 1 if unable to read directory structure
- Print error messages to stderr

## Environment

Requires:
- Ruby
- $top environment variable set to project root 