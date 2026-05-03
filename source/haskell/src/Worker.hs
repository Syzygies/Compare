-- Worker module: hot loop performance-critical code
{-# LANGUAGE Strict #-}

module Worker (runPrefix, algName) where

import Begin
import qualified Data.Vector.Unboxed as V
import qualified Data.Vector.Unboxed.Mutable as MV

-- Select Tarjan or Loops
import Tarjan; algName = "Tarjan"

-- Count cycles in a signed permutation
countCycles ::
   Int ->
   [Int] ->
   Int ->
   Relations s ->
   ST s Int
countCycles n perm signs rel = do
   reset rel (2 * n)
   forM_ (zip [0 ..] perm) $ \(i, j) ->
      if testBit signs i
         then unite rel i (j + n) >> unite rel (i + n) j
         else unite rel i j >> unite rel (i + n) (j + n)
   count rel

-- Tally cycle counts across all signs for one perm
tallySigns ::
   Int ->
   [Int] ->
   STVector s Int ->
   Relations s ->
   ST s ()
tallySigns n perm tally rel =
   forM_ [0 .. 2 ^ n - 1] $ \signs -> do
      c <- countCycles n perm signs rel
      MV.modify tally (+ 1) (2 * n - c)

-- Process one parcel: tally all cycle counts with given prefix
runPrefix :: Int -> [Int] -> ST s (Vector Int)
runPrefix n prefix = do
   tally <- MV.replicate (2 * n) 0
   rel <- create (2 * n)
   forM_ (map (prefix ++) (permutations rest)) $ \perm ->
      tallySigns n perm tally rel
   V.freeze tally
  where
   rest = [0 .. n - 1] \\ prefix
