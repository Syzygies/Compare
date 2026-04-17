// Parallel map via rayon

use rayon::prelude::*;

pub(crate) fn map<T, R, F>(tasks: Vec<T>, f: F) -> Vec<R>
where
    T: Send,
    R: Send,
    F: Fn(T) -> R + Send + Sync,
{
    tasks.into_par_iter().map(f).collect()
}
