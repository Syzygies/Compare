# size-dirs

Analyzes and displays the sizes of subdirectories within a given directory.

## Usage
```bash
size-dirs <directory>
```

## Core Behavior

The tool analyzes first-level subdirectories in the given path, skipping hidden directories (those starting with '.'). For each subdirectory, it:
- Recursively finds all files within it
- Sums their sizes and counts
- Calculates the average file size

Results are sorted by total size in descending order and displayed in a table using the TableFormatter module.

For example, in a project with a 300-byte source directory (two Ruby files of 100 and 200 bytes) and a 150-byte docs directory (single readme):

```
project/
├── src/
│   ├── main.rb
│   └── lib.rb
└── docs/
    └── readme.md
```

Running `size-dirs project` would output:
```
Subdirectory sizes in: project

Directory    Size (MB)    Count    Avg (MB)

src          0.00        2        0.00
docs         0.00        1        0.00

Total        0.00        3        0.00
```

## Data Structure

Each directory's stats are tracked in a hash:
```ruby
{
  "src" => { count: 2, size: 300 },
  "docs" => { count: 1, size: 150 }
}
```

## Implementation Notes
- Uses TableFormatter from common.rb for output
- Skips hidden directories (starting with '.')
- Recursively analyzes subdirectories
- Calculates average size per file

## History

### January 29, 2024
- Migrated to TableFormatter module
- Standardized output format

## Features

- Skips hidden directories (those starting with '.')
- Recursively analyzes all files in subdirectories
- Human-readable sizes in megabytes:
  - One decimal place for sizes and percentages
  - Two decimal places for averages
- Right-justified numeric columns using header widths
- Formatted table output using `column` command

## Examples

```bash
size-dirs /path/to/project
``` 