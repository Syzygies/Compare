-- Re-export the standard imports used across the project

module Begin
   ( module Control.Monad
   , module Control.Monad.ST
   , module Data.Bits
   , module Data.List
   , module Data.STRef
   , module Data.Vector.Unboxed
   , module Data.Vector.Unboxed.Mutable
   , (+=)
   , (-=)
   ) where

import Control.Monad (forM_, when)
import Control.Monad.ST
import Data.Bits (testBit)
import Data.List (foldl', permutations, (\\))
import Data.STRef
import Data.Vector.Unboxed (Vector)
import Data.Vector.Unboxed.Mutable (STVector)

-- Strict in-place increment/decrement on an STRef
infixl 1 +=, -=

(+=) :: Num a => STRef s a -> a -> ST s ()
ref += n = modifySTRef' ref (+ n)

(-=) :: Num a => STRef s a -> a -> ST s ()
ref -= n = modifySTRef' ref (subtract n)
