// Tarjan's Union-Find Algorithm

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
        var here = a

        while root[here] != here {
            here = root[here]
        }
        let top = here

        here = a
        while root[here] != top {
            let next = root[here]
            root[here] = top
            here = next
        }

        return top
    }

    public func unite(_ a: Int, _ b: Int) {
        let a = find(a)
        let b = find(b)

        if a != b {
            sets -= 1
            root[a] = b
        }
    }

    public func setCount() -> Int {
        return sets
    }
}
