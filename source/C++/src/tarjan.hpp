// Tarjan's Union-Find Algorithm

#pragma once

#include <vector>

class Tarjan {
    std::vector<int> root;
    int sets;

public:
    static constexpr const char* name = "Tarjan";

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

        while (root[current] != current) {
            current = root[current];
        }
        int root_val = current;

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
