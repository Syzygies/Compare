# Doc Scrape: Intelligent Documentation Harvesting Tool

A tool for downloading and processing web documentation with precise control over content scope and intelligent file filtering.

## Core Features

1. Smart Source Management:
   - Configurable documentation sources
   - Test and production configurations
   - Directory structure preservation
   - Logging for transparency

2. Intelligent File Filtering:
   - Uses Common::Extensions for detection
   - Two-tier filtering system:
     - wget's built-in filtering (pdf, fonts)
     - Custom filtering for special cases (html?)
   - Preserves essential content

## Usage

### Download Documentation
```bash
doc-scrape --download lean  # Full Lean 4 docs
doc-scrape --download fp    # Functional Programming book
doc-scrape --download blog  # Blog section (medium test)
doc-scrape --download test  # People page (small test)
doc-scrape --download      # Show available sources
```

### Process Content
```bash
doc-scrape --process lean  # Process downloaded content
```

## Directory Structure

All paths are relative to project root `$top`:

```
ref/
├── fetched/                     Downloaded content
│   ├── lean-lang.org/          Lean 4 docs
│   ├── lean-blog/              Blog section
│   ├── lean-test/              Test subset
│   └── download.log            wget activity log
└── extracted/                   Processed content
    ├── lean-lang.org/          Matches fetched
    ├── lean-blog/              Matches fetched
    └── lean-test/              Matches fetched
```

## Source Configuration

Each source defines:
```ruby
{
  'url' => 'https://lean-lang.org/',  # Must end with /
  'fetch_path' => 'ref/fetched/lean-lang.org',
  'extract_path' => 'ref/extracted/lean-lang.org',
  'description' => 'Full Lean 4 documentation'
}
```

Available sources:
- lean: Full Lean 4 documentation
- fp: Functional Programming in Lean book
- blog: Blog section (medium test case)
- test: People page (smallest test case)

## Implementation Details

### File Filtering

1. wget-level filtering:
   ```ruby
   WGET_SKIP_EXTENSIONS = %w[pdf ttf otf woff woff2 eot]
   ```
   Skips binary and font files during download

2. Custom filtering:
   ```ruby
   OUR_SKIP_EXTENSIONS = %w[html?]  # Keeping svg? for analysis
   ```
   Uses Common::Extensions for detection

### Download Process
1. Validate source configuration
2. Create empty target directory
3. Download with wget restrictions
4. Clean unwanted files
5. Log operations

### Content Processing
Currently in development:
- HTML parsing with Nokogiri
- Semantic structure extraction
- Format transformation

## Requirements

### Dependencies
- Ruby 2.0+
- Nokogiri gem
- wget
- Common::Extensions module

### Safety & Boundaries
- URL validation and domain restriction
- Empty directory requirement
- Controlled file type filtering
- Operation logging
- Memory-efficient processing
- All operations logged for review
- Fail fast with clear error messages
- Preserve existing processed content

### Error Handling
- Clear download failure indicators
- Processing state validation
- Format generation verification
- Actionable error messages
- Recovery procedures documented

## Example Usage

1. List Available Sources:
   ```bash
   doc-scrape --download
   # Shows configured documentation sources
   # Displays source descriptions
   ```

2. Download Documentation:
   ```bash
   doc-scrape --download lean
   # Downloads Lean documentation to ref/fetched/lean-lang.org/
   # Creates empty target directory
   # Logs activity to download.log
   
   doc-scrape --download test
   # Downloads test page to ref/fetched/lean-test/
   # Demonstrates focused documentation subset
   ```

3. Process Content:
   ```bash
   doc-scrape --process lean
   # Processes content from ref/fetched/lean-lang.org/
   # Generates output in ref/extracted/lean-lang.org/
   
   doc-scrape --process test
   # Processes content from ref/fetched/lean-test/
   # Generates output in ref/extracted/lean-test/
   ```

Each source maintains its own fetch/extract directory pair, allowing independent processing and clear separation of content.

## Why This Matters

This tool enables:
1. Consistent documentation access
2. Format optimization for different uses
3. Evolution of processing strategies
4. Clear operation history
5. Efficient updates and regeneration

The multi-format approach ensures documentation serves both human and AI needs effectively while maintaining semantic consistency across all forms.

## History

### January 28, 2024 - Initial Tool Creation
- Moved from reference/bin to top-level bin/
- Established documentation structure
- Set up version tracking
- Full context: today/01-28/lean-doc-conversion/

Previous versions and development notes are in versions/. This history section tracks significant changes and links to their full context in daily work folders. 