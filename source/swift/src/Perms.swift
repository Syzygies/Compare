// Signed Permutation Cycle Counting

import Foundation

let VERSION = 4

// Generate initial permutation for each possible prefix
func enumPrefixes(_ n: Int, _ k: Int) -> [[Int]] {
    let rest = Array(0..<n)
    
    func pick(_ k: Int, _ prefix: [Int], _ rest: [Int]) -> [[Int]] {
        if k == 0 {
            return [prefix + rest]
        } else {
            var results: [[Int]] = []
            for x in rest {
                let sansX = rest.filter { $0 != x }
                results += pick(k - 1, prefix + [x], sansX)
            }
            return results
        }
    }
    
    return pick(k, [], rest)
}

// Distribute parcels across workers and combine results
func runParcels(_ n: Int, _ k: Int, _ cores: Int) -> [Int64] {
    let prefixes = enumPrefixes(n, k)
    let zero = Array(repeating: Int64(0), count: 2 * n)
    
    // Use parallelMap to process prefixes
    let results = parallelMap(cores, zero, { prefix in
        runPrefix(n, k, prefix)
    }, prefixes)
    
    // Combine results
    guard !results.isEmpty else { return zero }
    
    var combined = results[0]
    for i in 1..<results.count {
        for j in 0..<combined.count {
            combined[j] += results[i][j]
        }
    }
    
    return combined
}

// Entry point for cycle distribution computation
func runAll(_ n: Int, _ k: Int, _ cores: Int) -> [Int64] {
    return runParcels(n, k, cores)
}

// Parse command-line arguments
func parseArgs(_ args: [String]) -> (Int, Int, Int)? {
    guard args.count == 4 else {
        fputs("Error: Required arguments: n prefix cores\n", stderr)
        return nil
    }
    
    guard let n = Int(args[1]),
          let prefix = Int(args[2]),
          let cores = Int(args[3]) else {
        fputs("Error: Invalid arguments\n", stderr)
        return nil
    }
    
    return (n, prefix, cores)
}

// Entry point
@main
struct Main {
    static func main() {
        guard let args = parseArgs(CommandLine.arguments) else {
            exit(1)
        }
        
        let (n, k, cores) = args
        
        print("\(Relations.name) v\(VERSION), n = \(n), prefix = \(k), cores = \(cores)")
        
        let result = runAll(n, k, cores)
        checkResult(n, result)
    }
}
