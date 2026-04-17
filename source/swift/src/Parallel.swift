// Generic parallel map utility

import Foundation
import Dispatch

// Synchronous parallel map that handles async execution internally
public func parallelMap<T, R>(_ cores: Int, _ init: R, _ f: @escaping (T) -> R, _ tasks: [T]) -> [R] {
    guard !tasks.isEmpty else { return [] }
    
    var results = [R?](repeating: nil, count: tasks.count)
    let semaphore = DispatchSemaphore(value: 0)
    
    Task {
        await withTaskGroup(of: (Int, R).self) { group in
            // Limited concurrency based on cores parameter
            var taskIndex = 0
            
            // Start initial batch
            for _ in 0..<min(cores, tasks.count) {
                let index = taskIndex
                let task = tasks[index]
                taskIndex += 1
                group.addTask {
                    return (index, f(task))
                }
            }
            
            // Collect results and launch new tasks as old ones complete
            for await (index, result) in group {
                results[index] = result
                
                // Launch next task if available
                if taskIndex < tasks.count {
                    let nextIndex = taskIndex
                    let nextTask = tasks[nextIndex]
                    taskIndex += 1
                    group.addTask {
                        return (nextIndex, f(nextTask))
                    }
                }
            }
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    return results.compactMap { $0 }
}