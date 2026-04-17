-- Signed Permutation Cycle Counting

import Control.Applicative ((<$>), (<*>))
import Control.Monad
import Control.Monad.ST
import Data.List (foldl')
import Data.Vector.Unboxed (Vector)
import qualified Data.Vector.Unboxed as V
import qualified Data.Vector.Unboxed.Mutable as MV
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Text.Printf (printf)
import Text.Read (readMaybe)

import Answers (check)
import Parallel (parallelMap)
import Worker (runPrefix, algName)

version :: Int
version = 17

-- Generate initial permutation for each possible prefix
enumPrefixes :: Int -> Int -> [[Int]]
enumPrefixes _ 0 = [[]]
enumPrefixes n k =
   [ x : p
   | p <- enumPrefixes n (k - 1)
   , x <- [0 .. n - 1]
   , x `notElem` p
   ]

-- Distribute work parcels and combine results
runParcels :: Int -> Int -> Vector Int
runParcels n prefix =
   let parcels = enumPrefixes n prefix
       worker p = runST (runPrefix n p)
       results = parallelMap worker parcels
       zero = V.replicate (2 * n) 0
    in foldl' (V.zipWith (+)) zero results

-- Parse command-line arguments
parseArgs :: [String] -> Maybe (Int, Int, Int)
parseArgs [n, prefix, cores] =
   (,,)
      <$> readMaybe n
      <*> readMaybe prefix
      <*> readMaybe cores
parseArgs _ = Nothing

-- Main entry point
main :: IO ()
main = do
   args <- getArgs
   case parseArgs args of
      Just (n, prefix, cores) -> do
         printf
            "%s v%d, n = %d, prefix = %d, cores = %d\n"
            algName
            version
            n
            prefix
            cores

         let result = runParcels n prefix
         let list = V.toList result

         check n list
      Nothing ->
         hPutStrLn stderr "Required arguments: n prefix cores"
            >> exitFailure
