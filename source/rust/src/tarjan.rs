// Tarjan's Union-Find Algorithm

#[allow(dead_code)]
pub(crate) struct Tarjan {
    seed: Vec<usize>,
    root: Vec<usize>,
    sets: usize,
}

#[allow(dead_code)]
impl Tarjan {
    pub(crate) const NAME: &'static str = "Tarjan";

    pub(crate) fn create(n: usize) -> Self {
        let seed: Vec<usize> = (0..n).collect();
        let root = vec![0; n];
        Tarjan { seed, root, sets: n }
    }

    pub(crate) fn reset(&mut self, n: usize) {
        self.root[..n].copy_from_slice(&self.seed[..n]);
        self.sets = n;
    }

    fn find(&mut self, a: usize) -> usize {
        let mut here = a;

        while self.root[here] != here {
            here = self.root[here];
        }
        let top = here;

        here = a;
        while self.root[here] != top {
            let next = self.root[here];
            self.root[here] = top;
            here = next;
        }

        top
    }

    pub(crate) fn unite(&mut self, a: usize, b: usize) {
        let a = self.find(a);
        let b = self.find(b);

        if a != b {
            self.sets -= 1;
            self.root[a] = b;
        }
    }

    pub(crate) fn set_count(&self) -> usize {
        self.sets
    }
}
