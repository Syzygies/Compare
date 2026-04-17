# size-exts

Analyzes file extensions in a directory tree using smart extension detection from the Common::Extensions module.

## Usage
```bash
size-exts <directory> [label]
```

Provide an optional label (A-Z) to list all files with that extension. For example, if the table shows "js" files under label "A", use `size-exts project A` to see all JavaScript files.

## Core Behavior

The tool recursively analyzes files in a directory tree and produces a statistical analysis:

1. Extension Detection:
   Uses Common::Extensions.detect() which employs a two-pass approach:
   ```ruby
   # Examples:
   script.min.js       → js
   page.html?xyz       → html?
   data.json~          → json~
   .gitignore          → gitignore
   README              → (no extension)
   ```

2. Statistical Analysis:
   - Groups files by extension
   - Calculates total and average sizes
   - Sorts by total size in descending order
   - Assigns A-Z labels for reference

3. Table Generation:
   Uses Common::TableFormatter to create aligned tables with:
   - Right-justified numeric columns
   - Controlled decimal places
   - Smart column spacing

## Output Format

Basic analysis shows a table with:
- Label: A-Z identifier for each extension
- Extension: The detected file extension
- Size (MB): Total size with 1 decimal place
- Percent: Percentage of total with 1 decimal place
- Count: Number of files
- Avg (MB): Average size with 2 decimal places

Example:
```
File extensions in: web-project

Label    Extension    Size (MB)    Percent    Count    Avg (MB)

A        js              0.02        66.7         2       0.01
B        html?           0.01        33.3         1       0.01

         Total           0.03                     3       0.01
```

When a label is specified, the tool additionally lists all files with that extension:
```
A        Files with extension 'js':

lib/jquery.min.js
src/app.js
```

## Implementation Details

1. Directory Traversal:
   ```ruby
   Dir.glob("#{path}/**/*").each do |file|
     next unless File.file?(file)
     ext = Common::Extensions.detect(file)
     # ... collect statistics
   end
   ```

2. Data Collection:
   - Uses a hash with default values for extension stats
   - Stores relative paths for readable file listings
   - Maintains running totals for size and count

3. Output Formatting:
   - Uses Common::TableFormatter for consistent table layout
   - Formats numbers with appropriate precision
   - Aligns columns for readability

## Requirements

### Dependencies
- Ruby standard library
- Common::Extensions module
- Common::TableFormatter module

### Safety & Boundaries
- Read-only operation on filesystem
- Memory efficient for large directories
- Handles invalid paths gracefully
- Maintains readable output format
- Supports arbitrary directory depth

### Error Handling
- Clear error for missing directory
- Validates label input (A-Z)
- Handles filesystem access errors
- Manages column formatting gracefully
- Reports empty directories clearly

## Example Usage

1. Basic Analysis:
   ```bash
   size-exts ref/fetched
   # Shows extension statistics for fetched content
   ```

2. File Listing:
   ```bash
   size-exts ref/fetched A
   # Shows statistics and lists files for top extension
   ```

## Why This Matters

This tool enables:
1. Understanding content structure
2. Identifying file categories
3. Finding outliers and patterns
4. Planning content processing
5. Guiding download filtering

The smart extension detection is particularly valuable for web content where extensions may include version markers or query strings.

## History

### January 29, 2024
- Migrated to TableFormatter module
- Standardized output format

### January 28, 2024 - Initial Tool Creation
- Moved from reference/bin to top-level bin/
- Established documentation structure
- Set up version tracking
- Full context: today/01-28/lean-doc-conversion/

Previous versions and development notes are in versions/. This history section tracks significant changes and links to their full context in daily work folders. 