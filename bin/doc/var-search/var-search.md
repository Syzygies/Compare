# Var-Search Command

This is a specification for implementing `bin/var-search`, a command that searches for environment variable usage patterns in a codebase. It helps identify where and how environment variables are used to assist in safe renaming.

## How It Works

1. Takes an environment variable name as argument (without $ or {})
2. Searches for three distinct patterns:
   - `${VAR}` - curly brace syntax
   - `$VAR` - direct reference syntax
   - `VAR` - raw text (filtered for relevant contexts)
3. Excludes:
   - `.git` directory
   - Workspace configuration files
   - Matches where VAR is part of a longer variable name
4. Groups results by pattern type for easier analysis

## Implementation Notes

- Use `Find` module for recursive directory traversal
- Skip binary files using `File.binary?` check
- Present results in organized sections by pattern type
- Colorize output for better readability
- Handle edge cases like empty input, invalid paths
- Support for exact matches only (avoid partial matches)

## Usage

```bash
var-search VARNAME    # Search for all patterns of VARNAME
```

## Output Format

Results grouped by pattern type with color-coded sections:
```
${VARNAME} matches:
  ./path/to/file1:line_number:full line content
  ./path/to/file2:line_number:full line content

$VARNAME matches:
  ./path/to/file3:line_number:full line content

VARNAME declaration matches:
  ./path/to/file4:line_number:full line content
```

## Environment Requirements

- Assumes `$top` (`$PROJECT_ROOT`) environment variable defines project root
- Ruby standard library only (no external gems)
- POSIX-compliant filesystem 