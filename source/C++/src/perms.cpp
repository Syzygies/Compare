// Signed Permutation Cycle Counting

#include <functional>
#include <iostream>
#include <optional>
#include <string>
#include <tuple>
#include <vector>

#include "answers.hpp"
#include "parallel.hpp"

const int version = 6;

// Generate initial permutation for each possible prefix
std::vector<std::vector<int>> enum_prefixes(int n, int k) {
    std::vector<int> rest;
    for (int i = 0; i < n; ++i) {
        rest.push_back(i);
    }

    std::function<std::vector<std::vector<int>>(int, std::vector<int>, std::vector<int>)> pick;
    pick = [&](int k, std::vector<int> prefix, std::vector<int> rest) -> std::vector<std::vector<int>> {
        if (k == 0) {
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

// Entry point for cycle distribution computation
std::vector<long long> run_all(int n, int k, int cores) {
    auto prefixes = enum_prefixes(n, k);
    if (prefixes.empty()) return std::vector<long long>(2 * n, 0);
    return run_parcels<Relations>(n, k, cores, prefixes);
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

int main(int argc, char* argv[]) {
    auto args = parse_args(argc, argv);
    if (!args) {
        return 1;
    }

    auto [n, k, cores] = *args;

    std::cout << Relations::name << " v" << version << ", n = " << n
              << ", prefix = " << k << ", cores = " << cores << std::endl;

    auto result = run_all(n, k, cores);
    check_result(n, result);

    return 0;
}
