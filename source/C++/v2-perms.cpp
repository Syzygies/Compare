// Signed Permutation Cycle Counting

#include <iostream>
#include <vector>
#include <numeric>
#include <string>
#include <functional>
#include <thread>
#include <algorithm>
#include <future>
#include <optional>

const int version = 2;

// --- Algorithm Implementations ---

// Tarjan's Union-Find Algorithm
class Tarjan {
    std::vector<int> root;
    int sets;

public:
    const static char* name;

    void create(int n) {
        root.resize(n);
        reset(n);
    }

    void reset(int n) {
        for (int i = 0; i < n; ++i) {
            root[i] = i;
        }
        sets = n;
    }

    int find(int a) {
        int current = a;
        
        // Find root
        while (root[current] != current) {
            current = root[current];
        }
        int root_val = current;
        
        // Path compression
        current = a;
        while (root[current] != root_val) {
            int next = root[current];
            root[current] = root_val;
            current = next;
        }
        
        return root_val;
    }

    void unite(int a, int b) {
        int a_root = find(a);
        int b_root = find(b);
        if (a_root != b_root) {
            sets--;
            root[a_root] = b_root;
        }
    }

    int set_count() const {
        return sets;
    }
};
const char* Tarjan::name = "Tarjan";

// The Loops Algorithm
class Loops {
    std::vector<int> ends;
    int sets;

public:
    const static char* name;

    void create(int n) {
        ends.resize(n);
        reset(n);
    }

    void reset(int n) {
        for (int i = 0; i < n; ++i) {
            ends[i] = i;
        }
        sets = 0;
    }

    void unite(int a, int b) {
        int ea = ends[a];
        int eb = ends[b];
        
        if (ea == b) {
            sets++;
        } else {
            ends[ea] = eb;
            ends[eb] = ea;
        }
    }

    int set_count() const {
        return sets;
    }
};
const char* Loops::name = "Loops";

// --- Algorithm Selection ---
using Relations = Tarjan; // Select Tarjan or Loops

// --- Helper Functions ---

// Swap utility
void swap_elements(std::vector<int>& arr, int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

// Generate initial permutation for each possible prefix
std::vector<std::vector<int>> enum_prefixes(int n, int k) {
    std::vector<int> rest;
    for (int i = 0; i < n; ++i) {
        rest.push_back(i);
    }
    
    std::function<std::vector<std::vector<int>>(int, std::vector<int>, std::vector<int>)> pick;
    pick = [&](int k, std::vector<int> prefix, std::vector<int> rest) -> std::vector<std::vector<int>> {
        if (k == 0) {
            // Combine prefix and rest
            std::vector<int> result = prefix;
            result.insert(result.end(), rest.begin(), rest.end());
            return {result};
        } else {
            std::vector<std::vector<int>> results;
            for (int x : rest) {
                std::vector<int> sans_x;
                for (int r : rest) {
                    if (r != x) sans_x.push_back(r);
                }
                std::vector<int> new_prefix = prefix;
                new_prefix.push_back(x);
                auto sub_results = pick(k - 1, new_prefix, sans_x);
                results.insert(results.end(), sub_results.begin(), sub_results.end());
            }
            return results;
        }
    };
    
    return pick(k, {}, rest);
}

// Heap's algorithm: tally all perms with a fixed length k prefix
void tally_perms(std::vector<int>& perm, int k, const std::function<void(std::vector<int>&)>& work) {
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
template<typename R>
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
template<typename R>
void tally_signs(int n, std::vector<int>& perm, std::vector<long long>& tally, R& rel) {
    int max_bits = 1 << n;
    
    for (int signs = 0; signs < max_bits; ++signs) {
        int cycles = count_cycles(n, perm, signs, rel);
        int index = 2 * n - cycles;
        tally[index]++;
    }
}

// Process one parcel: tally all cycle counts with given prefix
template<typename R>
std::vector<long long> run_prefix(int n, int k, const std::vector<int>& prefix) {
    std::vector<int> perm = prefix;  // Already a complete permutation
    std::vector<long long> tally(2 * n, 0);
    R rel;
    rel.create(2 * n);
    
    auto work = [&](std::vector<int>& perm) {
        tally_signs(n, perm, tally, rel);
    };
    
    tally_perms(perm, k, work);
    return tally;
}

// Distribute parcels across worker tasks and combine results
template<typename R>
std::vector<long long> run_parcels(int n, int k, const std::vector<std::vector<int>>& prefixes) {
    std::vector<std::future<std::vector<long long>>> futures;
    
    // Launch async tasks for each prefix
    for (const auto& prefix : prefixes) {
        futures.push_back(std::async(std::launch::async, [n, k, prefix]() {
            return run_prefix<R>(n, k, prefix);
        }));
    }
    
    // Collect and combine results
    std::vector<long long> final_tally(2 * n, 0);
    for (auto& future : futures) {
        auto tally = future.get();
        for (int i = 0; i < 2 * n; ++i) {
            final_tally[i] += tally[i];
        }
    }
    
    return final_tally;
}

// Entry point for cycle distribution computation
std::vector<long long> run_all(int n, int k) {
    auto prefixes = enum_prefixes(n, k);
    return run_parcels<Relations>(n, k, prefixes);
}

// Parse command-line arguments
std::optional<std::tuple<int, int, int>> parse_args(int argc, char* argv[]) {
    if (argc != 4) {
        std::cerr << "Error: Required arguments: n prefix cores" << std::endl;
        return std::nullopt;
    }
    
    int n = std::stoi(argv[1]);
    int prefix = std::stoi(argv[2]);
    int cores = std::stoi(argv[3]);
    
    return std::make_tuple(n, prefix, cores);
}

// Known correct cycle distributions for n=1 through n=12
const std::vector<std::vector<long long>> answers = {
    {}, // n=0
    {1, 1}, // n=1
    {1, 2, 3, 2}, // n=2
    {1, 3, 9, 13, 14, 8}, // n=3
    {1, 4, 18, 40, 81, 100, 92, 48}, // n=4
    {1, 5, 30, 90, 265, 501, 840, 940, 784, 384}, // n=5
    {1, 6, 45, 170, 655, 1666, 3991, 6790, 10124, 10568, 8224, 3840}, // n=6
    {1, 7, 63, 287, 1365, 4361, 13517, 30773, 64806, 102172, 140280, 138880, 102528, 46080}, // n=7
    {1, 8, 84, 448, 2534, 9744, 36988, 105344, 284817, 597800, 1149736, 1709568, 2205328, 2092928, 1481472, 645120}, // n=8
    {1, 9, 108, 660, 4326, 19446, 87276, 298236, 981969, 2568121, 6304608, 12424104, 22310672, 31651344, 38859648, 35613440, 24348672, 10321920}, // n=9
    {1, 10, 135, 930, 6930, 35652, 184590, 735540, 2851173, 8918338, 26548171, 64954890, 148217720, 277595888, 472103088, 644197280, 759435776, 675712512, 448598016, 185794560}, // n=10
    {1, 11, 165, 1265, 10560, 61182, 358842, 1633170, 7278513, 26480311, 92489969, 269869821, 744136030, 1724911408, 3714053376, 6668218128, 10845694816, 14319093888, 16313026048, 14148642816, 9157754880, 3715891200}, // n=11
    {1, 12, 198, 1672, 15455, 99572, 652344, 3338016, 16806207, 69688564, 279097566, 944926632, 3048785169, 8406183500, 21809957444, 48330322480, 99223087216, 171865587520, 269237405888, 345481734400, 382192970752, 324143788032, 205186498560, 81749606400} // n=12
};

// Check result against known answers  
void check_result(int n, const std::vector<long long>& result) {
    for (size_t i = 0; i < result.size(); ++i) {
        std::cout << result[i] << (i == result.size() - 1 ? "" : " ");
    }
    std::cout << std::endl;
    
    if (n <= 12) {
        const auto& expected = answers[n];
        bool correct = (result.size() == expected.size());
        if (correct) {
            for (size_t i = 0; i < expected.size(); ++i) {
                if (result[i] != expected[i]) {
                    correct = false;
                    break;
                }
            }
        }
        
        if (correct) {
            std::cout << "✓" << std::endl;
        } else {
            std::cout << "✗" << std::endl;
            for (size_t i = 0; i < expected.size(); ++i) {
                std::cout << expected[i] << (i == expected.size() - 1 ? "" : " ");
            }
            std::cout << std::endl;
        }
    } else {
        std::cout << "?" << std::endl;
    }
}

// Entry point
int main(int argc, char* argv[]) {
    auto args = parse_args(argc, argv);
    if (!args) {
        return 1;
    }
    
    auto [n, k, cores] = *args;
    
    std::cout << Relations::name << " v" << version << ", n = " << n 
              << ", prefix = " << k << ", cores = " << cores << std::endl;
    
    auto result = run_all(n, k);
    check_result(n, result);
    
    return 0;
}