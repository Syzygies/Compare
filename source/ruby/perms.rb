#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thread'

VERSION = 1

# Tarjan union-find data structure for tracking connected components
class Tarjan
  attr_reader :sets

  def initialize(n)
    @root = Array.new(n) { |i| i }
    @sets = n
  end

  def find(a)
    return a if @root[a] == a

    @root[a] = find(@root[a])
  end

  def unite(a, b)
    a = find(a)
    b = find(b)
    return if a == b

    @sets -= 1
    @root[a] = b
  end
end

# Loop data structure for finding cycles
class Loops
  attr_reader :sets

  def initialize(n)
    # Each entry points to itself initially
    @ends = Array.new(n) { |i| i }
    @sets = 0 # Start with zero cycles counted
  end

  # Process a relation (a,b) and update cycle count
  def unite(a, b)
    a_end = @ends[a]
    b_end = @ends[b]
    
    if a_end == b
      # Record a loop, and abandon entries not needed again
      @sets += 1
    else
      # Connect the two paths by updating their endpoints
      @ends[a_end] = b_end
      @ends[b_end] = a_end
    end
  end
end

# Generate all permutations with a fixed prefix using Heap's algorithm
def heap_permute(a, prefix_len, n = a.size, &block)
  if n <= prefix_len
    yield a.dup
  else
    (prefix_len...n).each do |i|
      heap_permute(a, prefix_len, n - 1, &block)
      j = (n.even?) ? i : prefix_len
      a[j], a[n - 1] = a[n - 1], a[j]
    end
  end
end

# Generate all prefixes of length prefix for permutations of size n
def generate_prefixes(n, prefix)
  prefixes = []
  (0...n).to_a.combination(prefix).each do |combo|
    combo.permutation.each do |perm|
      prefixes << perm
    end
  end
  prefixes
end

# Process a single parcel of work (permutations with a fixed prefix)
def process_parcel(n, prefix)
  # Initialize perm array
  perm = (0...n).to_a
  
  # Apply the prefix
  prefix.each_with_index do |val, idx|
    pos = perm.index(val)
    perm[idx], perm[pos] = perm[pos], perm[idx]
  end
  
  # Cycle count distribution array
  tally = Array.new(2 * n, 0)
  
  # Generate all permutations with this prefix
  heap_permute(perm, prefix.length) do |perm|
    # Apply filter and count cycles for all 2^n sign patterns
    perm_tally = count_cycle_patterns(n, perm)
    
    # Combine tallies
    perm_tally.each_with_index do |count, i|
      tally[i] += count
    end
  end
  
  tally
end

# Count cycles from each sign pattern for a given permutation
def count_cycle_patterns(n, perm)
  # Cycle count distribution array
  tally = Array.new(2 * n, 0)

  # Generate all 2^n sign patterns
  (0...(1 << n)).each do |sign_bits|
    # Count cycles for this specific sign pattern
    cycles = count_cycles(n, perm, sign_bits)

    # Formula places small cycle counts at beginning of array
    index = 2 * n - cycles
    tally[index] += 1 if index >= 0 && index < tally.length
  end

  tally
end

# Calculate number of cycles for a permutation with given sign pattern
def count_cycles(n, perm, sign_bits)
  # Create 2n elements (n pairs)
  relations = Relations.new(2 * n)

  # For each position i in the permutation
  (0...n).each do |i|
    j = perm[i] # Already 0-based

    # Calculate pair indices (each element i becomes a pair 2i, 2i+1)
    i_pair = [2 * i, 2 * i + 1]
    j_pair = [2 * j, 2 * j + 1]

    # Check if this position has a sign flip (1 in the sign_bits)
    sign_flip = (sign_bits & (1 << i)) != 0

    if sign_flip
      # With negative sign, connect i's first to j's second and i's second to j's first
      relations.unite(i_pair[0], j_pair[1])
      relations.unite(i_pair[1], j_pair[0])
    else
      # With positive sign, connect i's first to j's first and i's second to j's second
      relations.unite(i_pair[0], j_pair[0])
      relations.unite(i_pair[1], j_pair[1])
    end
  end

  # The number of connected components equals the number of cycles
  relations.sets
end

# Process permutations with parallel workers
def permutations(n, prefix, cores)
  
  # Generate prefixes
  prefixes = generate_prefixes(n, prefix)
  
  # Prepare result array
  result = Array.new(2 * n, 0)
  
  # Always use parallel architecture
  queue = Queue.new
  prefixes.each { |prefix| queue << prefix }
  
  # Add sentinels to signal workers to stop
  cores.times { queue << nil }
  
  # Create a mutex for result aggregation
  mutex = Mutex.new
  
  # Create worker threads
  workers = cores.times.map do
    Thread.new do
      # Thread-local results
      local_result = Array.new(2 * n, 0)
      
      # Process parcels until we get a nil sentinel
      while (prefix = queue.pop)
        # Process this parcel
        tally = process_parcel(n, prefix)
        
        # Update local results
        tally.each_with_index { |count, i| local_result[i] += count }
      end
      
      # Aggregate results with mutex protection
      mutex.synchronize do
        local_result.each_with_index { |count, i| result[i] += count }
      end
    end
  end
  
  # Wait for all workers to finish
  workers.each(&:join)
  
  result
end

# Known distribution by input size
def answers
  {
    1 => [1, 1],
    2 => [1, 2, 3, 2],
    3 => [1, 3, 9, 13, 14, 8],
    4 => [1, 4, 18, 40, 81, 100, 92, 48],
    5 => [1, 5, 30, 90, 265, 501, 840, 940, 784, 384],
    6 => [1, 6, 45, 170, 655, 1666, 3991, 6790, 10_124, 10_568, 8224, 3840],
    7 => [1, 7, 63, 287, 1365, 4361, 13_517, 30_773, 64_806, 102_172, 140_280,
          138_880, 102_528, 46_080],
    8 => [1, 8, 84, 448, 2534, 9744, 36_988, 105_344, 284_817, 597_800, 1_149_736,
          1_709_568, 2_205_328, 2_092_928, 1_481_472, 645_120],
    9 => [1, 9, 108, 660, 4326, 19_446, 87_276, 298_236, 981_969, 2_568_121,
          6_304_608, 12_424_104, 22_310_672, 31_651_344, 38_859_648, 35_613_440,
          24_348_672, 10_321_920],
    10 => [1, 10, 135, 930, 6930, 35_652, 184_590, 735_540, 2_851_173, 8_918_338,
           26_548_171, 64_954_890, 148_217_720, 277_595_888, 472_103_088, 644_197_280,
           759_435_776, 675_712_512, 448_598_016, 185_794_560],
    11 => [1, 11, 165, 1265, 10_560, 61_182, 358_842, 1_633_170, 7_278_513, 26_480_311,
           92_489_969, 269_869_821, 744_136_030, 1_724_911_408, 3_714_053_376,
           6_668_218_128, 10_845_694_816, 14_319_093_888, 16_313_026_048,
           14_148_642_816, 9_157_754_880, 3_715_891_200],
    12 => [1, 12, 198, 1672, 15_455, 99_572, 652_344, 3_338_016, 16_806_207,
           69_688_564, 279_097_566, 944_926_632, 3_048_785_169, 8_406_183_500,
           21_809_957_444, 48_330_322_480, 99_223_087_216, 171_865_587_520,
           269_237_405_888, 345_481_734_400, 382_192_970_752, 324_143_788_032,
           205_186_498_560, 81_749_606_400]
  }
end

# Select Tarjan or Loops
Relations = Tarjan

# Main execution
begin
  # Parse command line arguments
  n = Integer(ARGV[0])
  prefix = Integer(ARGV[1])
  cores = Integer(ARGV[2])
  
  # Validate n is in valid range
  if n < 1 || n > 12
    warn "Error: n must be in range 1..12"
    exit 1
  end
  
  # Validate prefix is in valid range
  if prefix < 1 || prefix > n
    warn "Error: prefix must be in range 1..#{n}"
    exit 1
  end
  
  # Print version and configuration
  algorithm_name = Relations == Tarjan ? "Tarjan" : "Loops"
  puts "#{algorithm_name} v#{VERSION}, n = #{n}, prefix = #{prefix}, cores = #{cores}\n"
  
  # Get the result
  result = permutations(n, prefix, cores)
  
  # Output the result
  puts result.join(' ')
  
  # Validate result (n is guaranteed to be 1-12)
  if answers[n] == result
    puts '✓'
  else
    puts "✗"
    puts answers[n].join(' ')
  end
rescue ArgumentError, TypeError => e
  warn "Error: #{e.message}"
  exit 1
end