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
        int here = a;

        while (root[here] != here) {
            here = root[here];
        }
        int top = here;

        here = a;
        while (root[here] != top) {
            int next = root[here];
            root[here] = top;
            here = next;
        }

        return top;
    }

    void unite(int a, int b) {
        a = find(a);
        b = find(b);
        if (a != b) {
            sets--;
            root[a] = b;
        }
    }

    int set_count() const {
        return sets;
    }
};
