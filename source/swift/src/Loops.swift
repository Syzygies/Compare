// The Loops Algorithm

import Foundation

public class Loops {
    public static let name = "Loops"
    private var ends: [Int]
    private(set) var sets: Int

    public init(n: Int) {
        ends = Array(0..<n)
        sets = 0
    }

    public func reset(n: Int) {
        sets = 0
        for i in 0..<n {
            ends[i] = i
        }
    }

    public func unite(_ a: Int, _ b: Int) {
        let ea = ends[a]
        let eb = ends[b]

        if ea == b {
            sets += 1
        } else {
            ends[ea] = eb
            ends[eb] = ea
        }
    }
    
    public func setCount() -> Int {
        return sets
    }
}