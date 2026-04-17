{-# LANGUAGE BangPatterns #-}

import Control.Monad
import Control.Monad.ST (ST, stToIO)
import Data.Bits
import Data.Vector.Unboxed (Vector)
import qualified Data.Vector.Unboxed as V
import Data.Vector.Unboxed.Mutable (STVector)
import qualified Data.Vector.Unboxed.Mutable as MV
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

import Tarjan (Relations, count, create, name, reset, unite) -- Select Tarjan or Loops
import Answers (check)
import Parallel (parallelMap)

-- Version
version = 15

-- Prefix generation
prefixes :: Int -> Int -> [[Int]]
prefixes _ 0 = [[]]
prefixes n k =
   [ x : p
   | p <- prefixes n (k - 1)
   , x <- [0 .. n - 1]
   , x `notElem` p
   ]

-- Heap's algorithm
heap ::
   Int ->
   Int ->
   STVector s Int ->
   (STVector s Int -> ST s ()) ->
   ST s ()
heap n j perm work = gen n
  where
   gen k
      | k == j = work perm
      | otherwise = do
         gen (k - 1)
         forM_ [j .. k - 2] $ \i -> do
            let idx = if even (k - j) then i else j
            swap perm idx (k - 1)
            gen (k - 1)

   swap arr i j = do
      vi <- MV.read arr i
      vj <- MV.read arr j
      MV.write arr i vj
      MV.write arr j vi

-- Cycle counting
cycles ::
   Int ->
   STVector s Int ->
   Int ->
   Relations s ->
   ST s Int
cycles n perm signs rel = do
   reset rel (2 * n)
   forM_ [0 .. n - 1] $ \i -> do
      j <- MV.read perm i
      if testBit signs i
         then unite rel i (j + n) >> unite rel (i + n) j
         else unite rel i j >> unite rel (i + n) (j + n)
   count rel

-- Process one parcel
parcel :: Int -> [Int] -> IO (Vector Int)
parcel n prefix = stToIO $ do
   -- Setup permutation with prefix
   perm <- MV.generate n id
   forM_ (zip [0 ..] prefix) $ \(i, v) -> do
      j <- find_val perm i v
      swap perm i j

   -- Allocate tally and relations
   tally <- MV.replicate (2 * n) 0
   rel <- create (2 * n)

   -- Process all permutations
   heap n (length prefix) perm $ \p -> do
      forM_ [0 .. 2 ^ n - 1] $ \signs -> do
         c <- cycles n p signs rel
         let idx = 2 * n - c
         modifyArray tally idx (+ 1)

   V.freeze tally
  where
   find_val perm i v = loop i
     where
      loop j = do
         x <- MV.read perm j
         if x == v then return j else loop (j + 1)

   swap perm i j = do
      vi <- MV.read perm i
      vj <- MV.read perm j
      MV.write perm i vj
      MV.write perm j vi

   modifyArray arr i f = do
      v <- MV.read arr i
      MV.write arr i (f v)

-- Helper for modifying mutable vectors in IO
modifyMV :: MV.IOVector Int -> Int -> (Int -> Int) -> IO ()
modifyMV arr i f = do
   v <- MV.read arr i
   MV.write arr i (f v)

-- Tally cycles for all permutations
tally :: Int -> Int -> Int -> IO (Vector Int)
tally n prefix cores = do
   let parcels = prefixes n prefix
   results <- parallelMap cores (parcel n) parcels  -- No need for sequence now
   res <- MV.replicate (2 * n) 0
   forM_ results $ \partial ->
      forM_ [0 .. 2 * n - 1] $ \i ->
         modifyMV res i (+ (partial V.! i))
   V.freeze res

-- Entry point
main :: IO ()
main = do
   args <- getArgs
   case args of
      [arg1, arg2, arg3] -> do
         let n = read arg1 :: Int
         let prefix = read arg2 :: Int
         let cores = read arg3 :: Int

         putStrLn $
            name
               ++ " v"
               ++ show version
               ++ ", n = "
               ++ show n
               ++ ", prefix = "
               ++ show prefix
               ++ ", cores = "
               ++ show cores

         result <- tally n prefix cores
         let list = V.toList result

         check n list
      _ ->
         hPutStrLn stderr "Required arguments: n prefix cores"
            >> exitFailure
