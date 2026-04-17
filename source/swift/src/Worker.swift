// Worker functions for processing permutations

import Foundation

// Select Tarjan or Loops
public typealias Relations = Tarjan

// Swap utility
func swap(_ arr: inout [Int], _ i: Int, _ j: Int) {
    let temp = arr[i]
    arr[i] = arr[j]
    arr[j] = temp
}

// Heap's algorithm: tally all perms with a fixed length k prefix
func tallyPerms(_ perm: inout [Int], _ k: Int, _ work: (inout [Int]) -> Void)
  { let n = perm.count
    
    func generate(_ j: Int)
      { if j < k
          { work(&perm) }
        else
          { generate(j - 1)
            
            for i in k..<j
              { if (j - k) % 2 == 0
                  { swap(&perm, k, j) }
                else
                  { swap(&perm, i, j) }
                generate(j - 1) }}}
    
    generate(n - 1) }

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
public func runPrefix(_ n: Int, _ k: Int, _ prefix: [Int]) -> [Int64] {
    var perm = prefix  // Already a complete permutation
    var tally = ThreadLocal.getTally(size: 2 * n)
    let rel = ThreadLocal.getRelations(n: n)
    
    let work = { (perm: inout [Int]) in
        tallySigns(n, &perm, &tally, rel)
    }
    
    tallyPerms(&perm, k, work)
    return tally
}