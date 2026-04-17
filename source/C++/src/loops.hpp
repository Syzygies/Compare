// The Loops Algorithm

#pragma once

#include <vector>

class Loops {
    std::vector<int> ends;
    int sets;

public:
    static constexpr const char* name = "Loops";

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
