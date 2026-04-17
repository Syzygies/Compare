# OCaml Style Guide

## Core Philosophy
Write functional code that's readable first, clever second. Optimize only what's proven necessary in hot loops.

## Naming Conventions

### Variable Names
- **Length matches scope**: Single letters for loop indices, 3-4 letters for local variables, longer descriptive names for module-level
- **Real words preferred**: Use `signs` not `sgn`, `tally` not `acc`, from a Scrabble dictionary when possible
- **No redundant prefixes**: `list` not `prefix_list` when the context is clear
- **Shadowing is fine**: In functional code, shadow parameters with transformed values rather than inventing new names
  ```ocaml
  let unite t a b =
     let a = find t a in  (* Shadow a with its root *)
     let b = find t b in  (* Shadow b with its root *)
     if a <> b then ...
  ```

### Underscores
- Use sparingly for compound names
- Acceptable for major functions: `count_cycles`, `process_parcel`
- Avoid for local variables: use `ea`/`eb` not `a_end`/`b_end`

## Code Organization

### Section Headers
Every flush-left code block following a blank line needs a header comment:
```ocaml
(* Dependencies *)
module Task = Domainslib.Task

(* Algorithm selection *)
module Relations = Tarjan
```

### Comments
- **No obvious comments**: Never explain what code does if it's readable
- **Headers only**: Single-line section headers to aid navigation
- **Warnings when necessary**: Only comment gnarly issues that will cause repeated mistakes

## Functional Style

### Default to Functional
- Pattern match for argument parsing
- Use `Array.map2 (+)` over imperative loops for combining arrays
- Tail recursion over while loops (OCaml optimizes tail calls)
- Pipeline operators for data transformation

### When to Be Imperative
Only in hot loops where allocation matters:
- Reuse arrays with `Array.fill` rather than allocating new ones
- Use `for` loops for performance-critical iteration
- Keep union-find structures mutable and reset them

### Anonymous Functions
- **Single line only**: Multiline anonymous functions are "wasted vocabulary"
- **Name complex operations**: Extract and name anything that spans multiple lines
  ```ocaml
  (* Bad *)
  List.map (fun prefix ->
     Task.async pool (fun () ->
        process_parcel n prefix
     )
  ) prefixes
  
  (* Good *)
  let spawn prefix =
     Task.async pool (fun () -> process_parcel n prefix)
  in
  List.map spawn prefixes
  ```

## Memory Management

### Allocation Awareness
- **Hot loops**: Reuse structures, zero arrays rather than reallocating
- **Cold paths**: Prefer clean functional code, allocation is fine
- **Measure first**: Don't assume - profile before optimizing

### Example Trade-offs
```ocaml
(* Cold path: functional is better *)
let extend prefix =
   List.init n Fun.id
   |> List.filter (fun x -> not (List.mem x prefix))
   |> List.map (fun x -> x :: prefix)

(* Hot loop: imperative for performance *)
for signs = 0 to max - 1 do
   let cycles = count_cycles n perm signs rel in
   tally.(index) <- tally.(index) + 1
done
```

## Pattern Matching

### Completeness
Use `assert false` for impossible cases rather than dummy values:
```ocaml
match List.map (Task.await pool) tasks with
| tally :: tallies -> List.fold_left (Array.map2 (+)) tally tallies
| [] -> assert false  (* Documents invariant: list never empty *)
```

### Destructuring
Use pattern matching to extract and convert in one step:
```ocaml
let n, prefix, cores = match Array.to_list Sys.argv with
   | [_; n; p; c] -> int_of_string n, int_of_string p, int_of_string c
   | _ -> Printf.eprintf "Required arguments: n prefix cores\n"; exit 1
```

## Pipeline Style
Chain operations clearly without intermediate variables:
```ocaml
result
|> List.map string_of_int
|> String.concat " "
|> print_endline
```

## Summary
Write code for humans first, computers second. Be functional by default, imperative when measured performance demands it. Name things to build vocabulary, not to document the obvious. Every piece of code should be obviously correct rather than cleverly optimal.