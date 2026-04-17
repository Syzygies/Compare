// Parallel dispatch: lock-free queue across threads, with std::async fallback

#pragma once

#include <future>
#include <thread>
#include <vector>

#include "concurrentqueue.h"
#include "worker.hpp"

template <typename R>
inline void lock_free_worker(
    int n, int k,
    moodycamel::ConcurrentQueue<std::vector<int>>& task_queue,
    std::vector<long long>& result_slot
) {
    R rel;
    rel.create(2 * n);
    std::vector<int> current_task;

    auto work_on_perm = [&](std::vector<int>& p) {
        tally_signs(n, p, result_slot, rel);
    };

    while (task_queue.try_dequeue(current_task)) {
        tally_perms(current_task, k, work_on_perm);
    }
}

// std::async variant: one task per prefix, all-cores
template <typename R>
std::vector<long long> run_parcels_async(int n, int k, const std::vector<std::vector<int>>& prefixes) {
    std::vector<std::future<std::vector<long long>>> futures;

    for (const auto& prefix : prefixes) {
        futures.push_back(std::async(std::launch::async, [n, k, prefix]() {
            return run_prefix<R>(n, k, prefix);
        }));
    }

    std::vector<long long> final_tally(2 * n, 0);
    for (auto& future : futures) {
        auto tally = future.get();
        for (int i = 0; i < 2 * n; ++i) {
            final_tally[i] += tally[i];
        }
    }

    return final_tally;
}

// Lock-free queue variant: fixed thread count, each thread reuses a Relations
template <typename R>
std::vector<long long> run_parcels_lockfree(int n, int k, int cores, const std::vector<std::vector<int>>& prefixes) {
    unsigned int num_worker_threads = cores > 1 ? cores - 1 : 0;

    moodycamel::ConcurrentQueue<std::vector<int>> task_queue;
    for (const auto& prefix : prefixes) {
        task_queue.enqueue(prefix);
    }

    std::vector<std::vector<long long>> partial_tallies(cores, std::vector<long long>(2 * n, 0));

    std::vector<std::thread> threads;
    threads.reserve(num_worker_threads);

    for (unsigned int i = 0; i < num_worker_threads; ++i) {
        threads.emplace_back(lock_free_worker<R>, n, k, std::ref(task_queue), std::ref(partial_tallies[i]));
    }

    lock_free_worker<R>(n, k, task_queue, partial_tallies[cores - 1]);

    for (auto& t : threads) {
        t.join();
    }

    std::vector<long long> final_tally(2 * n, 0);
    for (const auto& partial_tally : partial_tallies) {
        for (int i = 0; i < 2 * n; ++i) {
            final_tally[i] += partial_tally[i];
        }
    }

    return final_tally;
}

// Dispatch: cores==0 uses async, otherwise lock-free queue
template <typename R>
std::vector<long long> run_parcels(int n, int k, int cores, const std::vector<std::vector<int>>& prefixes) {
    if (cores == 0) {
        return run_parcels_async<R>(n, k, prefixes);
    } else {
        return run_parcels_lockfree<R>(n, k, cores, prefixes);
    }
}
