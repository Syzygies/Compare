// Signed Permutation Cycle Counting

use std::env;
use std::cell::RefCell;
use rayon::prelude::*;

const VERSION: i32 = 3;

// Tarjan's Union-Find Algorithm
#[allow(dead_code)]
struct Tarjan {
    root: Vec<usize>,
    sets: usize,
}

#[allow(dead_code)]
impl Tarjan {
    const NAME: &'static str = "Tarjan";
    
    fn create(n: usize) -> Self {
        let mut root = Vec::with_capacity(n);
        for i in 0..n {
            root.push(i);
        }
        Tarjan { root, sets: n }
    }

    fn reset(&mut self, n: usize) {
        for i in 0..n {
            self.root[i] = i;
        }
        self.sets = n;
    }

    fn find(&mut self, a: usize) -> usize {
        let mut current = a;
        
        // Find root
        while self.root[current] != current {
            current = self.root[current];
        }
        let root_val = current;
        
        // Path compression
        current = a;
        while self.root[current] != root_val {
            let next = self.root[current];
            self.root[current] = root_val;
            current = next;
        }
        
        root_val
    }

    fn unite(&mut self, a: usize, b: usize) {
        let a_root = self.find(a);
        let b_root = self.find(b);
        
        if a_root != b_root {
            self.sets -= 1;
            self.root[a_root] = b_root;
        }
    }

    fn set_count(&self) -> usize {
        self.sets
    }
}

// The Loops Algorithm
#[allow(dead_code)]
struct Loops {
    ends: Vec<usize>,
    sets: usize,
}

#[allow(dead_code)]
impl Loops {
    const NAME: &'static str = "Loops";
    
    fn create(n: usize) -> Self {
        let mut ends = Vec::with_capacity(n);
        for i in 0..n {
            ends.push(i);
        }
        Loops { ends, sets: 0 }
    }

    fn reset(&mut self, n: usize) {
        for i in 0..n {
            self.ends[i] = i;
        }
        self.sets = 0;
    }

    fn unite(&mut self, a: usize, b: usize) {
        let ea = self.ends[a];
        let eb = self.ends[b];
        
        if ea == b {
            self.sets += 1;
        } else {
            self.ends[ea] = eb;
            self.ends[eb] = ea;
        }
    }

    fn set_count(&self) -> usize {
        self.sets
    }
}

// Select Tarjan or Loops
type Relations = Tarjan;

// Swap utility
fn swap(arr: &mut Vec<usize>, i: usize, j: usize) {
    let temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

// Generate initial permutation for each possible prefix
fn enum_prefixes(n: usize, k: usize) -> Vec<Vec<usize>> {
    let mut rest = Vec::new();
    for i in 0..n {
        rest.push(i);
    }
    
    fn pick(k: usize, prefix: Vec<usize>, rest: Vec<usize>) -> Vec<Vec<usize>> {
        if k == 0 {
            let mut result = prefix.clone();
            result.extend(rest);
            return vec![result];
        } else {
            let mut results = Vec::new();
            for &x in &rest {
                let sans_x: Vec<usize> = rest.iter().filter(|&&r| r != x).copied().collect();
                let mut new_prefix = prefix.clone();
                new_prefix.push(x);
                let mut sub_results = pick(k - 1, new_prefix, sans_x);
                results.append(&mut sub_results);
            }
            return results;
        }
    }
    
    pick(k, Vec::new(), rest)
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
    static THREAD_DATA: RefCell<(Relations, Vec<i64>)> = RefCell::new((Relations::create(48), vec![0; 48]));
}

// Process one parcel: tally all cycle counts with given prefix
fn run_prefix(n: usize, k: usize, prefix: Vec<usize>) -> Vec<i64> {
    THREAD_DATA.with(|data| {
        let mut data = data.borrow_mut();
        let (rel, tally) = &mut *data;
        
        // Ensure tally has right size and is cleared
        if tally.len() < 2 * n {
            tally.resize(2 * n, 0);
        }
        for i in 0..2 * n {
            tally[i] = 0;
        }
        
        let mut perm = prefix;  // Already a complete permutation
        let work = |perm: &mut Vec<usize>| {
            tally_signs(n, perm, tally, rel);
        };
        
        tally_perms(&mut perm, k, work);
        
        // Return a copy of the tally
        tally[0..2 * n].to_vec()
    })
}

// Distribute parcels across worker tasks and combine results
fn run_parcels(n: usize, k: usize, prefixes: Vec<Vec<usize>>) -> Vec<i64> {
    prefixes
        .into_par_iter()
        .map(|prefix| run_prefix(n, k, prefix))
        .reduce(
            || vec![0i64; 2 * n],
            |mut acc, tally| {
                for i in 0..2 * n {
                    acc[i] += tally[i];
                }
                acc
            }
        )
}

// Entry point for cycle distribution computation
fn run_all(n: usize, k: usize) -> Vec<i64> {
    let prefixes = enum_prefixes(n, k);
    run_parcels(n, k, prefixes)
}

// Parse command-line arguments
fn parse_args(args: Vec<String>) -> Option<(usize, usize, usize)> {
    if args.len() != 4 {
        eprintln!("Error: Required arguments: n prefix cores");
        return None;
    }
    
    let n = match args[1].parse::<usize>() {
        Ok(val) => val,
        Err(_) => {
            eprintln!("Error: n must be a positive integer");
            return None;
        }
    };
    
    let k = match args[2].parse::<usize>() {
        Ok(val) => val,
        Err(_) => {
            eprintln!("Error: prefix must be a non-negative integer");
            return None;
        }
    };
    
    let cores = match args[3].parse::<usize>() {
        Ok(val) => val,
        Err(_) => {
            eprintln!("Error: cores must be a positive integer");
            return None;
        }
    };
    
    Some((n, k, cores))
}

// Known correct cycle distributions for n=1 through n=12
fn answers(n: usize) -> Option<Vec<i64>> {
    match n {
        0 => Some(vec![]),
        1 => Some(vec![1, 1]),
        2 => Some(vec![1, 2, 3, 2]),
        3 => Some(vec![1, 3, 9, 13, 14, 8]),
        4 => Some(vec![1, 4, 18, 40, 81, 100, 92, 48]),
        5 => Some(vec![1, 5, 30, 90, 265, 501, 840, 940, 784, 384]),
        6 => Some(vec![1, 6, 45, 170, 655, 1666, 3991, 6790, 10124, 10568, 8224, 3840]),
        7 => Some(vec![1, 7, 63, 287, 1365, 4361, 13517, 30773, 64806, 102172, 140280,
                       138880, 102528, 46080]),
        8 => Some(vec![1, 8, 84, 448, 2534, 9744, 36988, 105344, 284817, 597800, 1149736,
                       1709568, 2205328, 2092928, 1481472, 645120]),
        9 => Some(vec![1, 9, 108, 660, 4326, 19446, 87276, 298236, 981969, 2568121,
                       6304608, 12424104, 22310672, 31651344, 38859648, 35613440,
                       24348672, 10321920]),
        10 => Some(vec![1, 10, 135, 930, 6930, 35652, 184590, 735540, 2851173, 8918338,
                        26548171, 64954890, 148217720, 277595888, 472103088, 644197280,
                        759435776, 675712512, 448598016, 185794560]),
        11 => Some(vec![1, 11, 165, 1265, 10560, 61182, 358842, 1633170, 7278513, 26480311,
                        92489969, 269869821, 744136030, 1724911408, 3714053376,
                        6668218128, 10845694816, 14319093888, 16313026048,
                        14148642816, 9157754880, 3715891200]),
        12 => Some(vec![1, 12, 198, 1672, 15455, 99572, 652344, 3338016, 16806207,
                        69688564, 279097566, 944926632, 3048785169, 8406183500,
                        21809957444, 48330322480, 99223087216, 171865587520,
                        269237405888, 345481734400, 382192970752, 324143788032,
                        205186498560, 81749606400]),
        _ => None,
    }
}

// Check result against known answers
fn check_result(n: usize, result: &Vec<i64>) {
    // Print result
    let result_str: Vec<String> = result.iter().map(|x| x.to_string()).collect();
    println!("{}", result_str.join(" "));
    
    // Validate
    if n <= 12 {
        if let Some(expected) = answers(n) {
            if expected == *result {
                println!("✓");
            } else {
                println!("✗");
                let expected_str: Vec<String> = expected.iter().map(|x| x.to_string()).collect();
                println!("{}", expected_str.join(" "));
            }
        }
    } else {
        println!("?");
    }
}

// Entry point
fn main() {
    let args: Vec<String> = env::args().collect();
    
    match parse_args(args) {
        Some((n, k, cores)) => {
            // Set up thread pool
            // Note: cores-1 worker threads since the main thread also participates
            rayon::ThreadPoolBuilder::new()
                .num_threads(cores)
                .build_global()
                .unwrap();
            
            println!("{} v{}, n = {}, prefix = {}, cores = {}", 
                     Relations::NAME, VERSION, n, k, cores);
            
            let result = run_all(n, k);
            check_result(n, &result);
        }
        None => {
            std::process::exit(1);
        }
    }
}