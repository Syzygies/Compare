// Tarjan's Union-Find Algorithm

import Foundation

public class Tarjan {
    public static let name = "Tarjan"
    private var root: [Int]
    private(set) var sets: Int

    public init(n: Int) {
        root = Array(0..<n)
        sets = n
    }

    public func reset(n: Int) {
        sets = n
        for i in 0..<n {
            root[i] = i
        }
    }

    public func find(_ a: Int) -> Int {
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

    public func unite(_ a: Int, _ b: Int) {
        let aRoot = find(a)
        let bRoot = find(b)

        if aRoot != bRoot {
            sets -= 1
            root[aRoot] = bRoot
        }
    }
    
    public func setCount() -> Int {
        return sets
    }
}