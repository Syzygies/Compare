#!/usr/bin/env ruby
# frozen_string_literal: true

# Stirling numbers of the first kind

def stirling(n, k)
  return 1 if n == k
  return 0 if k.zero?

  (n - 1) * stirling(n - 1, k) + stirling(n - 1, k - 1)
end

# Generate S_n cycle counts
# cycles(3) = [1, 3, 2]

def cycles(n)
  n.downto(1).map { |k| stirling(n, k) }
end

# Generate row n of Pascal's triangle
# pascal(3) = [1, 3, 3, 1]

def pascal(n)
  row = [1]
  n.times do |k|
    row << row[k] * (n - k) / (k + 1)
  end
  row
end

# Generate B_n cycle counts
# hyper(3) = [1, 3, 9, 13, 14, 8]

def hyper(n)
  sym = cycles n
  row = Array.new(2 * n, 0)
  n.times do |k|
    bin = pascal(n - k)
    (n - k + 1).times do |i|
      row[2 * k + i] += 2**k * sym[k] * bin[i]
    end
  end
  row
end

# Generate key hash
def generate_key(max_n)
  result = {}
  (1..max_n).each do |n|
    result[n] = hyper(n)
  end
  result
end

# Output key hash as Ruby code
require 'pp'
pp generate_key(12)
