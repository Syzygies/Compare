// Tarjan's Union-Find Algorithm

#[allow(dead_code)]
pub(crate) struct Tarjan {
    root: Vec<usize>,
    sets: usize,
}

#[allow(dead_code)]
impl Tarjan {
    pub(crate) const NAME: &'static str = "Tarjan";

    pub(crate) fn create(n: usize) -> Self {
        let mut root = Vec::with_capacity(n);
        for i in 0..n {
            root.push(i);
        }
        Tarjan { root, sets: n }
    }

    pub(crate) fn reset(&mut self, n: usize) {
        for i in 0..n {
            self.root[i] = i;
        }
        self.sets = n;
    }

    fn find(&mut self, a: usize) -> usize {
        let mut current = a;

        while self.root[current] != current {
            current = self.root[current];
        }
        let root_val = current;

        current = a;
        while self.root[current] != root_val {
            let next = self.root[current];
            self.root[current] = root_val;
            current = next;
        }

        root_val
    }

    pub(crate) fn unite(&mut self, a: usize, b: usize) {
        let a_root = self.find(a);
        let b_root = self.find(b);

        if a_root != b_root {
            self.sets -= 1;
            self.root[a_root] = b_root;
        }
    }

    pub(crate) fn set_count(&self) -> usize {
        self.sets
    }
}
