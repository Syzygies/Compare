module Parallel (parallelMap) where

import Control.Concurrent (forkOS, newEmptyMVar, putMVar, takeMVar)
import Control.Monad (forM_, replicateM)
import Data.IORef (atomicModifyIORef', newIORef)
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as VM
import System.Random.Shuffle (shuffleM)

parallelMap ::
  Int ->
  (a -> IO b) ->  -- Changed from (a -> b) to (a -> IO b)
  [a] ->
  IO [b]
parallelMap cores f tasks
  | null tasks = return []
  | otherwise = do
      let taskVector = V.fromList tasks
      let count = V.length taskVector

      next <- newIORef 0
      results <- VM.new count

      order <- V.fromList <$> shuffleM [0 .. count - 1]

      let worker done = do
            let loop = do
                  index <- atomicModifyIORef' next (\i -> (i + 1, i))
                  if index < count
                    then do
                      let taskIndex = order V.! index
                      result <- f (taskVector V.! taskIndex)  -- Execute the IO action here
                      VM.write results taskIndex result
                      loop
                    else return ()
            loop
            putMVar done ()

      doneVars <- replicateM (cores - 1) newEmptyMVar

      forM_ doneVars $ \done -> forkOS (worker done)

      mainDone <- newEmptyMVar
      worker mainDone

      forM_ doneVars takeMVar

      V.toList <$> V.freeze results
