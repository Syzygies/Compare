module Parallel (parallelMap) where

import Control.Parallel.Strategies

parallelMap :: (a -> b) -> [a] -> [b]
parallelMap f tasks = withStrategy (parList rseq) (map f tasks)
