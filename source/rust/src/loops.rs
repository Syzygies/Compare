// The Loops Algorithm

#[allow(dead_code)]
pub(crate) struct Loops {
    ends: Vec<usize>,
    sets: usize,
}

#[allow(dead_code)]
impl Loops {
    pub(crate) const NAME: &'static str = "Loops";

    pub(crate) fn create(n: usize) -> Self {
        let mut ends = Vec::with_capacity(n);
        for i in 0..n {
            ends.push(i);
        }
        Loops { ends, sets: 0 }
    }

    pub(crate) fn reset(&mut self, n: usize) {
        for i in 0..n {
            self.ends[i] = i;
        }
        self.sets = 0;
    }

    pub(crate) fn unite(&mut self, a: usize, b: usize) {
        let ea = self.ends[a];
        let eb = self.ends[b];

        if ea == b {
            self.sets += 1;
        } else {
            self.ends[ea] = eb;
            self.ends[eb] = ea;
        }
    }

    pub(crate) fn set_count(&self) -> usize {
        self.sets
    }
}
