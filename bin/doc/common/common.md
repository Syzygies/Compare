# Common Functionality

This directory contains documentation for shared code used across multiple tools in the bin/ directory.

## Available Modules

### Extensions
Provides sophisticated file extension analysis for both analysis and filtering purposes:
- Two-pass extension detection:
  1. First pass finds "extension territory" after first dot
  2. Second pass extracts final extension from territory
- Handles compound extensions (e.g., min.js → js)
- Supports special cases (e.g., html? and svg?)
- Pattern matching for extension filtering

Methods:
- detect(filename): Returns the detected extension
- matches_pattern?(filename, pattern): Checks if file matches exact extension
- matches_any?(filename, patterns): Checks if file matches any extension pattern

### TableFormatter
Provides consistent table output formatting with precise control over spacing and alignment:
- Automatic column width calculation
- Right-justified numeric columns
- Smart spacing around headers and totals
- Decimal place control for numeric values

Methods:
- format_table(title, headers, rows, totals, numeric_cols): Formats and prints a complete table
- human_size_mb(bytes, decimal_places): Converts bytes to MB with controlled precision

## Core Philosophy

Our shared code follows these principles:

1. Clear Interfaces
   - Well-documented public methods
   - Consistent return types
   - Explicit error handling

2. Maintainable Design
   - Single responsibility per module
   - Pure functions where possible
   - DRY (Don't Repeat Yourself)
   - Shared code for common tasks

3. Smart Defaults
   - Sensible default behaviors
   - Optional parameters for flexibility
   - Safe error handling

## Usage

To use these modules in your Ruby scripts:

```ruby
require_relative 'common'

# Using Extensions
ext = Common::Extensions.detect('script.min.js')  # Returns 'js'

# Using TableFormatter
Common::TableFormatter.format_table(
  'My Table',
  ['Col1', 'Size (MB)'],
  [['A', '1.23']],
  ['Total', '1.23'],
  [1]  # Right-justify second column
)
```
