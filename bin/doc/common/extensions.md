# Extension Detection

This document specifies the shared extension detection functionality used across tools in the `bin/` directory.

## ExtensionDetector Module

Provides sophisticated file extension analysis that handles compound extensions, query parameters, and special cases.

### Core Behavior

The module uses a two-pass approach to detect extensions:

1. First Pass - Extension Territory:
   Starting after the first dot in the filename, collect characters following these rules:
   - Collect at least one letter or dot
   - Continue collecting letters and dots until one of:
     - End of filename is reached
     - Non-letter character is found
   - If a non-letter character is found, then:
     1. Include it in the extension
     2. Stop collecting
   
   For example:
   ```
   script.min.js     → min.js
   page.html?xyz     → html?
   data.json~        → json~
   .gitignore        → gitignore
   README            → (no extension)
   ```

2. Second Pass - Final Extension:
   If the territory from pass 1 contains any dots, extract everything after the last dot:
   ```
   script.min.js       → js
   jquery.slim.min.js  → js
   page.html?xyz       → html?
   ```

### Interface

The module provides these methods:

`detect_extension(filename)` returns a hash containing:
- `territory`: The full extension territory from first pass
- `extension`: The final extension from second pass
- `has_extension`: Boolean indicating if file has an extension

Example usage:
```ruby
result = detect_extension("script.min.js")
result.territory    # Returns "min.js"
result.extension    # Returns "js"
result.has_extension # Returns true
```

`classify_extension(filename)` returns a hash containing:
- All fields from `detect_extension`
- `content_type`: Symbol indicating content category (:text, :binary, etc)
- `download_priority`: Symbol indicating download importance (:essential, :optional, :skip)

Example usage:
```ruby
result = classify_extension("index.html?domain=Manual")
result.territory    # Returns "html?"
result.extension    # Returns "html?"
result.content_type # Returns :infrastructure
result.download_priority # Returns :skip
```

### Core Philosophy

1. Smart Extension Detection
   - Two-pass extension analysis for compound extensions
   - Handles special cases like 'min.js' and 'html?'
   - Recognizes extension territory vs final extension
   - Maintains context of full extension pattern
   - Files without extensions are properly categorized

2. Download Efficiency
   - Early classification of file types
   - Intelligent download priority assignment
   - Prevents unnecessary downloads
   - Respects bandwidth constraints

### Requirements

1. Safety & Boundaries
   - Pure functions with no side effects
   - Memory efficient string operations
   - Handles invalid input gracefully
   - Returns consistent data structures
   - Supports arbitrary path depth

2. Error Handling
   - Returns valid results for edge cases
   - Handles missing/malformed extensions
   - Reports errors without raising
   - Maintains type safety
   - Provides meaningful defaults

### Example Usage

```ruby
# Basic extension detection
detect_extension("script.min.js").extension     # => "js"
detect_extension("README").has_extension        # => false
detect_extension(".gitignore").extension        # => "gitignore"

# Smart classification
classify_extension("index.html?domain=Manual").download_priority  # => :skip
classify_extension("main.html").download_priority                # => :essential
classify_extension("style.min.css").content_type                # => :style
```

### Motivation & Insights

This module emerged from analyzing the Lean 4 documentation site, where we discovered parallel challenges in AI and web scraping:

1. Cognitive Limits
   - Like AI context windows, downloads have practical limits
   - Smart preprocessing helps work within these bounds
   - Early classification prevents wasted bandwidth/tokens
   - Focus on content-bearing files maximizes value

2. Infrastructure vs Content
   - In Lean's docs, 612.7MB (92.5%) are `.html?` files - a cross-reference database
   - Only 23.2MB (3.5%) are actual `.html` documentation content
   - Current `doc-scrape` treats all `.html` files the same
   - By detecting `.html?` as a distinct "virtual extension", we can skip 92.5% of the download
   - This isn't just optimization - it's the difference between useful and unusable results

3. Efficiency Through Understanding
   - Two-pass detection reflects how files are actually used
   - Territory captures developer intent (e.g. `min.js`, `slim.min.js`)
   - Final extension captures file type for processing
   - Classification enables upstream optimization

These insights shaped both the technical design and the broader goal: helping tools work smarter within practical limits.

### History

#### February 3, 2024 - Smart Extension Detection
- Extracted from `size-exts` into shared module
- Key design decisions:
  - Two-pass algorithm separates territory from final extension
  - Return full context (territory + extension) rather than just extension
  - Classify for download priority to respect bandwidth constraints
- Motivation:
  - Lean documentation analysis showed importance of query parameters
  - Same base extension (e.g. `.html`) can serve different purposes
  - Early classification prevents unnecessary downloads
- Full context in: today/02-03/refactor-extensions/ 