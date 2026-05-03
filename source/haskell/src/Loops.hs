-- Loops algorithm for cycle counting
{-# LANGUAGE Strict #-}

module Loops where

import Begin
import qualified Data.Vector.Unboxed.Mutable as MV

data Relations s = Relations
   { ends :: STVector s Int
   , sets :: STRef s Int
   }

create :: Int -> ST s (Relations s)
create n = do
   ends <- MV.generate n id
   sets <- newSTRef 0
   return Relations{ends, sets}

reset :: Relations s -> Int -> ST s ()
reset Relations{ends, sets} n = do
   forM_ [0 .. n - 1] $ \i -> MV.write ends i i
   writeSTRef sets 0

unite :: Relations s -> Int -> Int -> ST s ()
unite Relations{ends, sets} a b = do
   ea <- MV.read ends a
   eb <- MV.read ends b

   if ea == b
      then sets += 1
      else do
         MV.write ends ea eb
         MV.write ends eb ea

count :: Relations s -> ST s Int
count Relations{sets} = readSTRef sets
