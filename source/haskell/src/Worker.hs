{-# LANGUAGE Strict #-}

module Worker (runPrefix, algName) where

import Control.Applicative ((*>))
import Control.Monad
import Control.Monad.ST
import Data.Bits
import Data.Vector.Unboxed (Vector)
import qualified Data.Vector.Unboxed as V
import Data.Vector.Unboxed.Mutable (STVector)
import qualified Data.Vector.Unboxed.Mutable as MV

-- Select Tarjan or Loops
import Tarjan (Relations, count, create, reset, unite, name)

algName :: String
algName = name

-- Swap two elements in a mutable vector
swap :: STVector s Int -> Int -> Int -> ST s ()
swap arr i j = do
   vi <- MV.read arr i
   vj <- MV.read arr j
   MV.write arr i vj
   MV.write arr j vi

-- Heap's algorithm: tally all perms with a fixed length k prefix
tallyPerms ::
   Int ->
   Int ->
   STVector s Int ->
   (STVector s Int -> ST s ()) ->
   ST s ()
tallyPerms n j perm work = gen n
  where
   gen k
      | k == j = work perm
      | otherwise = do
         gen (k - 1)
         forM_ [j .. k - 2] $ \i -> do
            let idx = if even (k - j) then i else j
            swap perm idx (k - 1)
            gen (k - 1)

-- Count cycles in a signed permutation
countCycles ::
   Int ->
   STVector s Int ->
   Int ->
   Relations s ->
   ST s Int
countCycles n perm signs rel = do
   reset rel (2 * n)
   forM_ [0 .. n - 1] $ \i -> do
      j <- MV.read perm i
      if testBit signs i
         then unite rel i (j + n) *> unite rel (i + n) j
         else unite rel i j *> unite rel (i + n) (j + n)
   count rel

-- Tally cycle counts across all signs for one perm
tallySigns ::
   Int ->
   STVector s Int ->
   STVector s Int ->
   Relations s ->
   ST s ()
tallySigns n perm tally rel = do
   forM_ [0 .. 2 ^ n - 1] $ \signs -> do
      c <- countCycles n perm signs rel
      let idx = 2 * n - c
      MV.modify tally (+ 1) idx

-- Process one parcel: tally all cycle counts with given prefix
runPrefix :: Int -> [Int] -> ST s (Vector Int)
runPrefix n prefix = do
   perm <- MV.generate n id
   forM_ (zip [0 ..] prefix) $ \(i, v) -> do
      j <- find_val perm i v
      swap perm i j

   tally <- MV.replicate (2 * n) 0
   rel <- create (2 * n)

   let work p = tallySigns n p tally rel
   tallyPerms n (length prefix) perm work

   V.freeze tally
  where
   find_val perm i v = loop i
     where
      loop j = do
         x <- MV.read perm j
         if x == v then return j else loop (j + 1)
