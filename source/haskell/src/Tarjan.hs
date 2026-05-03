-- Tarjan union-find algorithm for cycle counting
{-# LANGUAGE Strict #-}

module Tarjan where

import Begin
import qualified Data.Vector.Unboxed.Mutable as MV

data Relations s = Relations
   { root :: STVector s Int
   , sets :: STRef s Int
   }

create :: Int -> ST s (Relations s)
create n = do
   root <- MV.generate n id
   sets <- newSTRef n
   return Relations{root, sets}

reset :: Relations s -> Int -> ST s ()
reset Relations{root, sets} n = do
   forM_ [0 .. n - 1] $ \i -> MV.write root i i
   writeSTRef sets n

find :: STVector s Int -> Int -> ST s Int
find root = go
  where
   go here = do
      parent <- MV.read root here
      if parent == here
         then return here
         else do
            top <- go parent
            MV.write root here top
            return top

unite :: Relations s -> Int -> Int -> ST s ()
unite Relations{root, sets} a b = do
   ra <- find root a
   rb <- find root b

   when (ra /= rb) $ do
      sets -= 1
      MV.write root ra rb

count :: Relations s -> ST s Int
count Relations{sets} = readSTRef sets
