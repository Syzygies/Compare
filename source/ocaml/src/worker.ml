(* Worker module: hot loop performance-critical code *)

(* Select Tarjan or Loops *)
module Sets = Tarjan let name = "Tarjan"

(* Heap's algorithm: tally all perms with a fixed length k prefix *)
let tally_perms perm k work =
  let n = Array.length perm in
  let swap = Parallel.swap in
  let rec generate j =
    if j < k then work perm
    else
      ( generate (j - 1);
        for i = k to j - 1 do
          if (j - k) mod 2 = 0 then swap perm k j else swap perm i j;
          generate (j - 1)
        done )
  in
  generate (n - 1)

(* Count cycles in a signed permutation *)
let count_cycles n perm signs rel =
  Sets.reset rel (2 * n);
  for i = 0 to n - 1 do
    let j = perm.(i) in
    if (signs lsr i) land 1 = 1 then
      ( Sets.unite rel i (j + n);
        Sets.unite rel (i + n) j )
    else
      ( Sets.unite rel i j;
        Sets.unite rel (i + n) (j + n) )
  done;
  Sets.set_count rel

(* Tally cycle counts across all signs for one perm *)
let tally_signs n perm tally rel =
  let maxBits = 1 lsl n in
  for signs = 0 to maxBits - 1 do
    let cycles = count_cycles n perm signs rel in
    let index = (2 * n) - cycles in
    tally.(index) <- tally.(index) + 1
  done

(* Process one parcel: tally all cycle counts with given prefix *)
let run_prefix n k perm =
  let perm = Array.of_list perm in
  let tally = Array.make (2 * n) 0 in
  let rel = Sets.create (2 * n) in
  let work perm = tally_signs n perm tally rel in
  tally_perms perm k work;
  tally
