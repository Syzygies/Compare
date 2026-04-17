// Signed Permutation Cycle Counting

import Foundation
import Dispatch

let VERSION = 3

// Tarjan's Union-Find Algorithm
class Tarjan {
    static let name = "Tarjan"
    private var root: [Int]
    private(set) var sets: Int

    init(n: Int) {
        root = Array(0..<n)
        sets = n
    }

    func reset(n: Int) {
        sets = n

        // Ensure we have enough capacity
        if root.count < n {
            root.reserveCapacity(n)
            root = Array(repeating: 0, count: n)
        }

        // Reset each element
        for i in 0..<n {
            root[i] = i
        }
    }

    func find(_ a: Int) -> Int {
        var current = a
        
        // Find root
        while root[current] != current {
            current = root[current]
        }
        let rootVal = current
        
        // Path compression
        current = a
        while root[current] != rootVal {
            let next = root[current]
            root[current] = rootVal
            current = next
        }
        
        return rootVal
    }

    func unite(_ a: Int, _ b: Int) {
        let aRoot = find(a)
        let bRoot = find(b)

        if aRoot != bRoot {
            sets -= 1
            root[aRoot] = bRoot
        }
    }
    
    func setCount() -> Int {
        return sets
    }
}

// The Loops Algorithm
class Loops {
    static let name = "Loops"
    private var ends: [Int]
    private(set) var sets: Int

    init(n: Int) {
        ends = Array(0..<n)
        sets = 0
    }

    func reset(n: Int) {
        sets = 0

        // Ensure we have enough capacity
        if ends.count < n {
            ends.reserveCapacity(n)
            ends = Array(repeating: 0, count: n)
        }

        // Reset each element to point to itself
        for i in 0..<n {
            ends[i] = i
        }
    }

    func unite(_ a: Int, _ b: Int) {
        let ea = ends[a]
        let eb = ends[b]

        if ea == b {
            sets += 1
        } else {
            ends[ea] = eb
            ends[eb] = ea
        }
    }
    
    func setCount() -> Int {
        return sets
    }
}

// Select Tarjan or Loops
typealias Relations = Tarjan

// Swap utility
func swap(_ arr: inout [Int], _ i: Int, _ j: Int) {
    let temp = arr[i]
    arr[i] = arr[j]
    arr[j] = temp
}


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

// Heap's algorithm: tally all perms with a fixed length k prefix
func tallyPerms(_ perm: inout [Int], _ k: Int, _ work: (inout [Int]) -> Void) {
    let n = perm.count
    
    func generate(_ j: Int) {
        if j < k {
            work(&perm)
        } else {
            generate(j - 1)
            
            for i in k..<j {
                if (j - k) % 2 == 0 {
                    swap(&perm, k, j)
                } else {
                    swap(&perm, i, j)
                }
                generate(j - 1)
            }
        }
    }
    
    generate(n - 1)
}

// Count cycles in a signed permutation
func countCycles(_ n: Int, _ perm: [Int], _ signs: Int, _ rel: Relations) -> Int {
    rel.reset(n: 2 * n)
    
    for i in 0..<n {
        let j = perm[i]
        
        if ((signs >> i) & 1) == 1 {
            rel.unite(i, j + n)
            rel.unite(i + n, j)
        } else {
            rel.unite(i, j)
            rel.unite(i + n, j + n)
        }
    }
    
    return rel.setCount()
}

// Tally cycle counts across all signs for one perm
func tallySigns(_ n: Int, _ perm: inout [Int], _ tally: inout [Int64], _ rel: Relations) {
    let maxBits = 1 << n
    
    for signs in 0..<maxBits {
        let cycles = countCycles(n, perm, signs, rel)
        let index = 2 * n - cycles
        tally[index] += 1
    }
}

// Thread-local storage for Relations and tally to avoid repeated allocations
final class ThreadLocal {
    // Get thread-specific instance of Relations, create if needed
    static func getRelations(n: Int) -> Relations {
        let threadDict = Thread.current.threadDictionary
        let key = "relations"
        
        var relations = threadDict[key] as? Relations
        if relations == nil {
            relations = Relations(n: 2 * n)
            threadDict[key] = relations
        }
        
        relations!.reset(n: 2 * n)
        return relations!
    }
    
    // Get thread-specific array for tallying, create if needed
    static func getTally(size: Int) -> [Int64] {
        let threadDict = Thread.current.threadDictionary
        let key = "tally-\(size)"
        
        var tally = threadDict[key] as? [Int64]
        if tally == nil || tally!.count < size {
            tally = Array(repeating: 0, count: size)
            threadDict[key] = tally
        } else {
            // Reset to zeros
            for i in 0..<tally!.count {
                tally![i] = 0
            }
        }
        
        return tally!
    }
}

// Process one parcel: tally all cycle counts with given prefix
func runPrefix(_ n: Int, _ k: Int, _ prefix: [Int]) -> [Int64] {
    var perm = prefix  // Already a complete permutation
    var tally = ThreadLocal.getTally(size: 2 * n)
    let rel = ThreadLocal.getRelations(n: n)
    
    let work = { (perm: inout [Int]) in
        tallySigns(n, &perm, &tally, rel)
    }
    
    tallyPerms(&perm, k, work)
    return tally
}

// Actor for safely collecting results from async tasks
actor ResultCollector {
    var result: [Int64]
    
    init(size: Int) {
        result = Array(repeating: 0, count: size)
    }
    
    func add(_ partial: [Int64]) {
        for i in 0..<min(result.count, partial.count) {
            result[i] += partial[i]
        }
    }
    
    func get() -> [Int64] {
        return result
    }
}

// Helper function to run async code synchronously
func runAsyncAndWait(_ operation: @escaping () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await operation()
        semaphore.signal()
    }
    semaphore.wait()
}

// Distribute parcels across worker tasks and combine results
func runParcels(_ n: Int, _ k: Int, _ cores: Int, _ prefixes: [[Int]]) -> [Int64] {
    let collector = ResultCollector(size: 2 * n)
    var finalResult: [Int64] = []
    
    // Using runAsyncAndWait to make the async Task run synchronously from this function
    runAsyncAndWait {
        if cores == 0 {
            // Use all available cores (including efficiency cores)
            await withTaskGroup(of: [Int64].self) { group in
                for prefix in prefixes {
                    group.addTask {
                        return runPrefix(n, k, prefix)
                    }
                }

                for await partial in group {
                    await collector.add(partial)
                }
            }
        } else {
            // Limit to specified number of concurrent tasks
            await withTaskGroup(of: [Int64].self) { group in
                var prefixIndex = 0
                
                // Start initial batch of tasks up to core limit
                for _ in 0..<min(cores, prefixes.count) {
                    let prefix = prefixes[prefixIndex]
                    prefixIndex += 1
                    group.addTask {
                        return runPrefix(n, k, prefix)
                    }
                }
                
                // Process results and schedule new tasks as old ones complete
                for await partial in group {
                    await collector.add(partial)
                    
                    // Schedule next task if available
                    if prefixIndex < prefixes.count {
                        let prefix = prefixes[prefixIndex]
                        prefixIndex += 1
                        group.addTask {
                            return runPrefix(n, k, prefix)
                        }
                    }
                }
            }
        }
        
        finalResult = await collector.get()
    }
    
    return finalResult
}

// Entry point for cycle distribution computation
func runAll(_ n: Int, _ k: Int, _ cores: Int) -> [Int64] {
    let prefixes = enumPrefixes(n, k)
    return runParcels(n, k, cores, prefixes)
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

// Known correct cycle distributions for n=1 through n=12
func answers(_ n: Int) -> [Int64]? {
    switch n {
    case 0: return []
    case 1: return [1, 1]
    case 2: return [1, 2, 3, 2]
    case 3: return [1, 3, 9, 13, 14, 8]
    case 4: return [1, 4, 18, 40, 81, 100, 92, 48]
    case 5: return [1, 5, 30, 90, 265, 501, 840, 940, 784, 384]
    case 6: return [1, 6, 45, 170, 655, 1666, 3991, 6790, 10124, 10568, 8224, 3840]
    case 7: return [1, 7, 63, 287, 1365, 4361, 13517, 30773, 64806, 102172, 140280,
                    138880, 102528, 46080]
    case 8: return [1, 8, 84, 448, 2534, 9744, 36988, 105344, 284817, 597800, 1149736,
                    1709568, 2205328, 2092928, 1481472, 645120]
    case 9: return [1, 9, 108, 660, 4326, 19446, 87276, 298236, 981969, 2568121,
                    6304608, 12424104, 22310672, 31651344, 38859648, 35613440,
                    24348672, 10321920]
    case 10: return [1, 10, 135, 930, 6930, 35652, 184590, 735540, 2851173, 8918338,
                     26548171, 64954890, 148217720, 277595888, 472103088, 644197280,
                     759435776, 675712512, 448598016, 185794560]
    case 11: return [1, 11, 165, 1265, 10560, 61182, 358842, 1633170, 7278513, 26480311,
                     92489969, 269869821, 744136030, 1724911408, 3714053376,
                     6668218128, 10845694816, 14319093888, 16313026048,
                     14148642816, 9157754880, 3715891200]
    case 12: return [1, 12, 198, 1672, 15455, 99572, 652344, 3338016, 16806207,
                     69688564, 279097566, 944926632, 3048785169, 8406183500,
                     21809957444, 48330322480, 99223087216, 171865587520,
                     269237405888, 345481734400, 382192970752, 324143788032,
                     205186498560, 81749606400]
    default: return nil
    }
}

// Check result against known answers
func checkResult(_ n: Int, _ result: [Int64]) {
    // Print result
    print(result.map(String.init).joined(separator: " "))
    
    // Validate
    if n <= 12 {
        if let expected = answers(n) {
            if expected == result {
                print("✓")
            } else {
                print("✗")
                print(expected.map(String.init).joined(separator: " "))
            }
        }
    } else {
        print("?")
    }
}

// Entry point
guard let args = parseArgs(CommandLine.arguments) else {
    exit(1)
}

let (n, k, cores) = args

print("\(Relations.name) v\(VERSION), n = \(n), prefix = \(k), cores = \(cores)")

let result = runAll(n, k, cores)
checkResult(n, result)