module Simulation (simulate) where

import Data.List (findIndex)
import System.Random (RandomGen, random)
import Types

-- | Elige el índice de la siguiente columna dada una fila de probabilidades
-- y un número u en [0,1): el primer índice cuya suma acumulada supera a u.
pickNext :: [Double] -> Double -> Int
pickNext row u =
  case findIndex (> u) (scanl1 (+) row) of
    Just i  -> i
    Nothing -> length row - 1   -- por errores de redondeo

-- | Un paso: de un estado (índice) al siguiente, devolviendo el generador nuevo.
step :: RandomGen g => Matrix -> g -> Int -> (Int, g)
step m g i = (pickNext (m !! i) u, g')
  where (u, g') = random g

-- | Trayectoria de n pasos desde el estado inicial (incluye el inicial,
-- por lo que regresa n + 1 índices).
simulate :: RandomGen g => Chain -> Int -> Int -> g -> [Int]
simulate (Chain _ m) start n g =
  take (n + 1) (map fst (iterate (\(i, gen) -> step m gen i) (start, g)))