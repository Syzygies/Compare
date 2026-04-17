// Worker module: hot loop performance-critical code

#pragma once

#include <functional>
#include <vector>

#include "loops.hpp"
#include "tarjan.hpp"

// Select Tarjan or Loops
using Relations = Tarjan;

inline void swap_elements(std::vector<int>& arr, int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

// Heap's algorithm: tally all perms with a fixed length k prefix
inline void tally_perms(std::vector<int>& perm, int k, const std::function<void(std::vector<int>&)>& work) {
    int n = perm.size();

    std::function<void(int)> generate = [&](int j) {
        if (j < k) {
            work(perm);
        } else {
            generate(j - 1);

            for (int i = k; i <= j - 1; ++i) {
                if ((j - k) % 2 == 0) {
                    swap_elements(perm, k, j);
                } else {
                    swap_elements(perm, i, j);
                }
                generate(j - 1);
            }
        }
    };

    generate(n - 1);
}

// Count cycles in a signed permutation
template <typename R>
int count_cycles(int n, std::vector<int>& perm, int signs, R& rel) {
    rel.reset(2 * n);

    for (int i = 0; i < n; ++i) {
        int j = perm[i];

        if (((signs >> i) & 1) == 1) {
            rel.unite(i, j + n);
            rel.unite(i + n, j);
        } else {
            rel.unite(i, j);
            rel.unite(i + n, j + n);
        }
    }

    return rel.set_count();
}

// Tally cycle counts across all signs for one perm
template <typename R>
void tally_signs(int n, std::vector<int>& perm, std::vector<long long>& tally, R& rel) {
    int max_bits = 1 << n;

    for (int signs = 0; signs < max_bits; ++signs) {
        int cycles = count_cycles(n, perm, signs, rel);
        int index = 2 * n - cycles;
        tally[index]++;
    }
}

// Process one parcel: tally all cycle counts with given prefix
template <typename R>
std::vector<long long> run_prefix(int n, int k, const std::vector<int>& prefix) {
    std::vector<int> perm = prefix;
    std::vector<long long> tally(2 * n, 0);
    R rel;
    rel.create(2 * n);

    auto work = [&](std::vector<int>& perm) {
        tally_signs(n, perm, tally, rel);
    };

    tally_perms(perm, k, work);
    return tally;
}
