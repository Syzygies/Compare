-- Loops algorithm for cycle counting
{-# LANGUAGE Strict #-}

module Loops where

import Control.Monad (forM_)
import Control.Monad.ST
import Data.STRef
import Data.Vector.Unboxed.Mutable (STVector)
import qualified Data.Vector.Unboxed.Mutable as MV

data Relations s = Relations
   { ends :: STVector s Int
   , loops :: STRef s Int
   }

create :: Int -> ST s (Relations s)
create n = do
   ends <- MV.generate n id
   loops <- newSTRef 0
   return $ Relations ends loops

reset :: Relations s -> Int -> ST s ()
reset l n = do
   forM_ [0 .. n - 1] $ \i -> MV.write (ends l) i i
   writeSTRef (loops l) 0

unite :: Relations s -> Int -> Int -> ST s ()
unite l a b = do
   ea <- MV.read (ends l) a
   eb <- MV.read (ends l) b

   if ea == b
      then modifySTRef' (loops l) (+ 1)
      else do
         MV.write (ends l) ea eb
         MV.write (ends l) eb ea

count :: Relations s -> ST s Int
count l = readSTRef (loops l)

name :: String
name = "Loops"
