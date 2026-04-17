-- Tarjan union-find algorithm for cycle counting
{-# LANGUAGE Strict #-}

module Tarjan where

import Control.Monad (forM_, when)
import Control.Monad.ST
import Data.STRef
import Data.Vector.Unboxed.Mutable (STVector)
import qualified Data.Vector.Unboxed.Mutable as MV

data Relations s = Relations
   { root :: STVector s Int
   , sets :: STRef s Int
   }

create :: Int -> ST s (Relations s)
create n = do
   root <- MV.generate n id
   sets <- newSTRef n
   return $ Relations root sets

reset :: Relations s -> Int -> ST s ()
reset t n = do
   forM_ [0 .. n - 1] $ \i -> MV.write (root t) i i
   writeSTRef (sets t) n

find :: Relations s -> Int -> ST s Int
find t a = do
   pa <- MV.read (root t) a
   if pa == a
      then return a
      else do
         r <- find t pa
         MV.write (root t) a r
         return r

unite :: Relations s -> Int -> Int -> ST s ()
unite t a b = do
   ra <- find t a
   rb <- find t b
   when (ra /= rb) $ do
      modifySTRef' (sets t) (subtract 1)
      MV.write (root t) ra rb

count :: Relations s -> ST s Int
count t = readSTRef (sets t)

name :: String
name = "Tarjan"
