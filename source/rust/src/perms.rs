// Signed Permutation Cycle Counting

use std::env;

mod answers;
mod loops;
mod parallel;
mod tarjan;
mod worker;

const VERSION: i32 = 3;

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
            vec![result]
        } else {
            let mut results = Vec::new();
            for &x in &rest {
                let sans_x: Vec<usize> = rest.iter().filter(|&&r| r != x).copied().collect();
                let mut new_prefix = prefix.clone();
                new_prefix.push(x);
                let mut sub_results = pick(k - 1, new_prefix, sans_x);
                results.append(&mut sub_results);
            }
            results
        }
    }

    pick(k, Vec::new(), rest)
}

// Distribute parcels across worker tasks and combine results
fn run_parcels(n: usize, k: usize, prefixes: Vec<Vec<usize>>) -> Vec<i64> {
    let results = parallel::map(prefixes, |prefix| worker::run_prefix(n, k, prefix));
    let mut acc = vec![0i64; 2 * n];
    for tally in results {
        for i in 0..2 * n {
            acc[i] += tally[i];
        }
    }
    acc
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

// Entry point
fn main() {
    let args: Vec<String> = env::args().collect();

    match parse_args(args) {
        Some((n, k, cores)) => {
            rayon::ThreadPoolBuilder::new()
                .num_threads(cores)
                .build_global()
                .unwrap();

            println!(
                "{} v{}, n = {}, prefix = {}, cores = {}",
                worker::Relations::NAME, VERSION, n, k, cores
            );

            let prefixes = enum_prefixes(n, k);
            let result = run_parcels(n, k, prefixes);
            answers::check_result(n, &result);
        }
        None => {
            std::process::exit(1);
        }
    }
}
