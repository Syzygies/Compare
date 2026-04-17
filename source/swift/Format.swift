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
