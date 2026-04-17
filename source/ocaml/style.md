# OCaml Style Guide

## Variable Naming

### Keep Names Short and Contextual
- **Good**: `size`, `count`, `rel`, `tally`
- **Bad**: `result_size`, `num_parcels`, `local_rel`, `local_tally`

Names should distinguish alternatives, not document lifecycle. In a function processing parcels, `rel` is obviously the relations tracker for that parcel. Adding `local_` is patronizing redundancy.

### Avoid Underscores
- **Exception**: Only when truly necessary for clarity (rarely)
- **Bad**: `local_tally`, `num_parcels`, `result_size`
- **Good**: `tally`, `count`, `size`

Underscores create visual speed bumps. Your eye must parse two words where one suffices.

### Let Context Provide Meaning
```ocaml
let body i =
   let rel = Relations.create size in  (* Obviously local to this iteration *)
   let tally = Array.make size 0 in    (* Context makes scope clear *)
   process_parcel n parcels.(i) rel tally
```

## Anonymous Functions

### Never Use Multi-line Anonymous Functions
**Bad**:
```ocaml
List.iteri (fun idx value ->
   let pos = ref idx in
   while perm.(!pos) <> value do
      incr pos
   done;
   swap perm idx !pos
) prefix;
```

**Good**:
```ocaml
let apply_prefix idx value =
   let pos = ref idx in
   while perm.(!pos) <> value do
      incr pos
   done;
   swap perm idx !pos
in
List.iteri apply_prefix prefix;
```

### Extract and Name Complex Logic
Multi-line anonymous functions are unreadable. Extract them into named functions with short, clear names that explain their role in context.

### Anonymous Functions Are Only for Trivial Operations
- Single expressions: `List.map (fun x -> x * 2) lst` ✓
- Simple predicates: `List.filter (fun x -> x > 0) lst` ✓
- Anything else: Use a named function

## Code Organization

### Define Helper Functions Close to Use
```ocaml
let work () =
   let parcels = Array.of_list prefixes in
   let count = Array.length parcels in
   
   let body i =  (* Defined where parcels is in scope *)
      let rel = Relations.create size in
      let tally = Array.make size 0 in
      process_parcel n parcels.(i) rel tally
   in
   
   Task.parallel_for_reduce ~start:0 ~finish:(count - 1) ~body pool combine init
```

### Use Begin...End for Clear Boundaries
When you must have a longer anonymous function (avoid if possible):
```ocaml
let results = Task.run pool begin fun () ->
   (* work here */
end in
```

Not `(fun () -> ...)` which buries the function start mid-line.

## General Principles

### Code Should Read Like Mathematics
Short variable names, clear structure, minimal ceremony. The algorithm should be visible, not buried under documentation-as-naming.

### Trust the Reader
Assume the reader understands the code's purpose. Don't encode documentation in variable names. If they need help, they'll read the actual documentation.

### Performance Matters But Clarity Matters More
Extract common operations (like `swap`) even if there's a microscopic performance cost. Duplicate code is harder to maintain than a function call is to optimize.

### Every Character Should Earn Its Place
If removing a character doesn't lose information, remove it. This applies to variable names, parentheses, and structure.