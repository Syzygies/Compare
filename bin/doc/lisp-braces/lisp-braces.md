# Lisp-style Braces for OCaml

## Purpose
Post-process ocamlformat output to convert K&R-style braces to Lisp-style, making OCaml code more readable by giving structure room to breathe.

## Core Insight
**Braces and parentheses follow identical formatting rules.** There are only three cases to handle, and the delimiter type (`{`/`}` vs `(`/`)`) is just a parameter, never a reason for different logic.

## The Three Cases

### 1. Single-line `{ }` without exposed semicolons
```ocaml
{message = "hello"}  →  { message = "hello" }
```
Just ensure spaces inside the delimiters. Skip parentheses without semicolons entirely.

### 2. Single-line with exposed semicolons
```ocaml
{x = 1; y = 2}  →  { x = 1; y = 2 }
```
For multiple fields on one line with prefix code:
```ocaml
type t = {x: int; y: int}  →  type t =
                                { x: int;
                                  y: int }
```

### 3. Multi-line blocks
When opening delimiter ends its line AND closing delimiter ends its line:
```ocaml
else (                      else
  Printf.printf "✗\n";  →     ( Printf.printf "✗\n";
  data |> process)              data |> process )
```

## Critical Implementation Details

### Unified Structure
Use a single Block structure with:
- `delimiter`: The opening character (`{` or `(`)
- `prefix`: Code before the delimiter on its line
- `content`: Either an array of fields (semicolon case) or raw string (multiline)
- `multiline`: Boolean flag
- `has_semicolon`: Boolean flag for exposed semicolons

### Parser Rules
1. **"Exposed" semicolon**: At depth 0 relative to the delimiter type. Track depth while scanning.
2. **Delimiter ends line**: Only whitespace between delimiter and newline.
3. **Don't parse `{{` or `((`**: These are different constructs in OCaml.

### Content Handling

#### Single-line with semicolons
Split on exposed semicolons into fields array. Preserve everything else including nested structures.

#### Multi-line blocks
1. **Strip leading newline after opening delimiter** - it's formatting, not content
2. **Preserve relative indentation** - find the base indent of content, remove it, then reapply with +2 spaces
3. **Closing delimiter stays on last line** - never waste a line

### Indentation Rules
- **Prefix is just whitespace**: Delimiter goes inline with content
- **Prefix has code**: Delimiter goes on new line, content indented +2 from base

### Edge Cases Handled
1. **Nested delimiters**: `{ outer = { inner = 1 } }` - depth tracking handles this
2. **Strings with delimiters**: `{ msg = "use {}" }` - lexer identifies strings
3. **Comments with delimiters**: `{ x = 1 (* note: } *) }` - lexer handles OCaml comments
4. **Operators**: `List.filter ((<>) x)` - parentheses without semicolons are ignored
5. **Empty content after stripping newline**: Check for this when formatting

## What NOT to Do

### Don't have separate code paths for `{` and `(`
They behave identically. Any divergence is a bug waiting to happen.

### Don't treat multiline semicolons specially
In multiline blocks, semicolons are just characters in the content. The whole block gets shifted as one unit.

### Don't parse more than needed
This is a formatter, not a compiler. Use Parslet for lexing (strings, comments, delimiters) but not full syntax parsing.

### Don't add debug flags
Save output and use diff tools. They're far more informative than colored terminal output.

## Testing Strategy
1. **Single-line braces without semicolons**: `{field = value}`
2. **Single-line braces with semicolons**: `{a = 1; b = 2}`
3. **Single-line parens with semicolons**: `(a; b; c)`
4. **Multi-line with code prefix**: `else (\n  ...\n  )`
5. **Multi-line with indent prefix**: `  (\n  ...\n  )`
6. **Nested structures**: Each type inside each type
7. **Real code files**: The ultimate test

## Implementation Architecture

### Three Classes, Clear Responsibilities

1. **OCamlLexer** (Parslet-based)
   - Tokenizes into: strings, comments, delimiters, semicolons, other
   - Returns flat token stream

2. **BlockFinder**
   - Scans token stream for delimited blocks
   - Determines if block should be formatted
   - Extracts prefix and content
   - Returns array of Block structures

3. **LispFormatter
   - Takes a Block, returns formatted string
   - Three methods: format_simple, format_with_fields, format_multiline
   - No side effects, pure transformation

### Main Flow
```ruby
source → tokens → blocks → formatted_blocks → output
```

Keep it simple. Each stage has one job and does it well.