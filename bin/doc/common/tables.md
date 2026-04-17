# Table Formatter

Provides consistent table output formatting with precise control over spacing and alignment.

## Interface

The module provides two methods:

`format_table(title, headers, rows, totals, numeric_cols)` formats a table for display with:
- Consistent spacing and right-justified numeric columns
- Headers determine minimum column widths
- Values wider than headers overflow rather than clip
- Numeric columns are right-justified using printf field widths

`human_size_mb(bytes, decimal_places = 1)` converts a byte count to a megabyte string:
- Default 1 decimal place for general sizes
- Optional decimal_places parameter for more precision
- Example: `human_size_mb(2_345_678)    # Returns "2.2"`
- Example: `human_size_mb(2_345_678, 2) # Returns "2.24"`

## Core Behavior

The formatter handles:
1. Column width calculation
   - Uses header width as minimum
   - Expands for wider content
   - Maintains alignment across rows

2. Numeric formatting
   - Right justification
   - Controlled decimal places
   - Consistent field widths

3. Special cases
   - Empty cells
   - Null values
   - Overflow handling

## Output Format

The formatted table includes:
1. Title with surrounding newlines
2. Headers that define minimum column widths
3. Right-justified numeric columns
4. Consistent decimal places (typically 1 for sizes, 2 for averages)
5. Values that exceed column width overflow rather than clip

Example output:
```
Subdirectory sizes in: ref/fetched/lean-lang.org/

Directory                         Size (MB)    Percent    Count    Avg (MB)

doc                                   625.1       94.4     1602        0.39
presentations                          17.5        2.6       66        0.27
lean4                                   7.7        1.2       73        0.10
functional_programming_in_lean          3.9        0.6       91        0.04
screenshots                             3.2        0.5       16        0.20
blog                                    2.5        0.4       19        0.13
theorem_proving_in_lean4                1.9        0.3       35        0.05
deps                                    0.1        0.0        2        0.03
-verso-js                               0.0        0.0        2        0.02
static                                  0.0        0.0        4        0.01
fonts                                   0.0        0.0        2        0.01
-verso-css                              0.0        0.0        1        0.00

Total                                 661.9                1913        0.35
```

## Requirements

### Safety & Boundaries
- Handles nil values gracefully
- Preserves string encoding
- Memory efficient string operations
- Maintains readable output format
- Supports arbitrary column counts

### Error Handling
- Returns empty string for nil input
- Validates numeric formatting
- Handles column mismatches
- Reports formatting errors
- Provides meaningful defaults

## Example Usage

```ruby
headers = ["Directory", "Size (MB)", "Count", "Avg (MB)"]
rows = [
  ["src", 1.234, 45, 0.027],
  ["docs", 3.456, 67, 0.052]
]
totals = ["Total", 4.69, 112, 0.042]
numeric_cols = [1, 2, 3]

puts format_table("Directory Sizes", headers, rows, totals, numeric_cols)
```

## History

### February 3, 2024
- Moved to dedicated documentation file
- Standardized format specification
- Added detailed requirements
- Expanded example usage 