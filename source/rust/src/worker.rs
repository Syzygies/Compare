// Worker module: hot loop performance-critical code

use std::cell::RefCell;

#[allow(unused_imports)]
use crate::loops::Loops;
#[allow(unused_imports)]
use crate::tarjan::Tarjan;

// Select Tarjan or Loops
pub(crate) type Relations = Tarjan;

fn swap(arr: &mut Vec<usize>, i: usize, j: usize) {
    let temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

// Heap's algorithm: tally all perms with a fixed length k prefix
fn tally_perms<F>(perm: &mut Vec<usize>, k: usize, mut work: F)
where
    F: FnMut(&mut Vec<usize>),
{
    let n = perm.len();

    fn generate<F>(perm: &mut Vec<usize>, j: usize, k: usize, work: &mut F)
    where
        F: FnMut(&mut Vec<usize>),
    {
        if j < k {
            work(perm);
        } else {
            generate(perm, j - 1, k, work);

            for i in k..j {
                if (j - k) % 2 == 0 {
                    swap(perm, k, j);
                } else {
                    swap(perm, i, j);
                }
                generate(perm, j - 1, k, work);
            }
        }
    }

    generate(perm, n - 1, k, &mut work);
}

// Count cycles in a signed permutation
fn count_cycles(n: usize, perm: &Vec<usize>, signs: usize, rel: &mut Relations) -> usize {
    rel.reset(2 * n);

    for i in 0..n {
        let j = perm[i];

        if ((signs >> i) & 1) == 1 {
            rel.unite(i, j + n);
            rel.unite(i + n, j);
        } else {
            rel.unite(i, j);
            rel.unite(i + n, j + n);
        }
    }

    rel.set_count()
}

// Tally cycle counts across all signs for one perm
fn tally_signs(n: usize, perm: &mut Vec<usize>, tally: &mut Vec<i64>, rel: &mut Relations) {
    let max_bits = 1 << n;

    for signs in 0..max_bits {
        let cycles = count_cycles(n, perm, signs, rel);
        let index = 2 * n - cycles;
        tally[index] += 1;
    }
}

// Thread-local storage for Relations and tally to avoid repeated allocations
thread_local! {
    static THREAD_DATA: RefCell<(Relations, Vec<i64>)> =
        RefCell::new((Relations::create(48), vec![0; 48]));
}

// Process one parcel: tally all cycle counts with given prefix
pub(crate) fn run_prefix(n: usize, k: usize, prefix: Vec<usize>) -> Vec<i64> {
    THREAD_DATA.with(|data| {
        let mut data = data.borrow_mut();
        let (rel, tally) = &mut *data;

        if tally.len() < 2 * n {
            tally.resize(2 * n, 0);
        }
        for i in 0..2 * n {
            tally[i] = 0;
        }

        let mut perm = prefix;
        let work = |perm: &mut Vec<usize>| {
            tally_signs(n, perm, tally, rel);
        };

        tally_perms(&mut perm, k, work);

        tally[0..2 * n].to_vec()
    })
}
