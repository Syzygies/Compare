# Signed Permutation Cycle Counting

const version = 1

include("tarjan.jl")
include("loops.jl")
include("answers.jl")

# Select Tarjan or Loops
const Sets = Tarjan

# Generate initial permutation for each possible prefix
function enum_prefixes(n::Int, k::Int)
   rest = collect(0:n-1)

   function pick(k::Int, prefix::Vector{Int}, rest::Vector{Int})
      if k == 0
         return [vcat(prefix, rest)]
      else
         result = Vector{Vector{Int}}()
         for x in rest
            sans_x = filter(y -> y != x, rest)
            append!(result, pick(k - 1, vcat(prefix, [x]), sans_x))
         end
         return result
      end
   end

   pick(k, Int[], rest)
end

# Heap's algorithm: tally all perms with a fixed length k prefix
function tally_perms!(perm::Vector{Int}, k::Int, work::Function)
   n = length(perm)

   function generate(j::Int)
      if j < k
         work(perm)
      else
         generate(j - 1)
         for i in k:j-1
            if (j - k) % 2 == 0
               perm[k+1], perm[j+1] = perm[j+1], perm[k+1]
            else
               perm[i+1], perm[j+1] = perm[j+1], perm[i+1]
            end
            generate(j - 1)
         end
      end
   end

   generate(n - 1)
end

# Count cycles in a signed permutation
function count_cycles(n::Int, perm::Vector{Int}, signs::Int, rel)
   reset!(rel, 2n)

   for i in 0:n-1
      j = perm[i+1]
      if (signs >> i) & 1 == 1
         unite!(rel, i, j + n)
         unite!(rel, i + n, j)
      else
         unite!(rel, i, j)
         unite!(rel, i + n, j + n)
      end
   end

   set_count(rel)
end

# Tally cycle counts across all signs for one perm
function tally_signs!(n::Int, perm::Vector{Int}, tally::Vector{Int}, rel)
   max_bits = 1 << n

   for signs in 0:max_bits-1
      cycles = count_cycles(n, perm, signs, rel)
      index = 2n - cycles + 1  # Julia uses 1-based indexing
      tally[index] += 1
   end
end

# Process one parcel: tally all cycle counts with given prefix
function run_prefix(n::Int, k::Int, perm::Vector{Int})
   perm = copy(perm)  # Make a mutable copy
   tally = zeros(Int, 2n)
   rel = create(Sets, 2n)

   work = p -> tally_signs!(n, p, tally, rel)
   tally_perms!(perm, k, work)

   tally
end

# Entry point: distribute work parcels and combine results
function run_parcels(n::Int, k::Int, cores::Int)
   zero = zeros(Int, 2n)
   prefixes = enum_prefixes(n, k)

   if cores == 1
      results = [run_prefix(n, k, p) for p in prefixes]
   else
      results = Vector{Vector{Int}}(undef, length(prefixes))
      Threads.@threads for i in 1:length(prefixes)
         results[i] = run_prefix(n, k, prefixes[i])
      end
   end

   # Combine results
   if isempty(results)
      return zero
   else
      return reduce((a, b) -> a .+ b, results)
   end
end

# Parse command-line arguments
function parse_args(args::Vector{String})
   if length(args) != 3
      println(stderr, "Error: Required arguments: n prefix cores")
      return nothing
   end

   try
      n = parse(Int, args[1])
      prefix = parse(Int, args[2])
      cores = parse(Int, args[3])
      return (n, prefix, cores)
   catch
      println(stderr, "Error: All arguments must be valid integers.")
      return nothing
   end
end

# Main entry point
function main()
   args = ARGS
   parsed = parse_args(args)

   if parsed === nothing
      exit(1)
   end

   n, k, cores = parsed

   println("$(name(Sets)) v$version, n = $n, prefix = $k, cores = $cores")

   result = run_parcels(n, k, cores)
   check(n, result)
end

# Run if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
   main()
end