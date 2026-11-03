module Markov (validate, distribution, stationary) where

import Matrix (vecMat)
import Types

tolerance :: Double
tolerance = 1e-9

-- | Revisa que la cadena sea una matriz cuadrada, sin negativos y con filas que suman 1.
validate :: Chain -> Either String Chain
validate c@(Chain names m)
  | n == 0                    = Left "Debe haber al menos un estado"
  | length m /= n             = Left "La matriz debe tener una fila por estado"
  | any ((/= n) . length) m   = Left "Cada fila debe tener una columna por estado"
  | any (any (< 0)) m         = Left "Hay probabilidades negativas"
  | ((i, r) : _) <- badRows   = Left ("La fila " ++ show i ++ " suma " ++ show (sum r) ++ ", debe sumar 1")
  | otherwise                 = Right c
  where
    n       = length names
    badRows = filter (\(_, r) -> abs (sum r - 1) > tolerance) (zip [1 :: Int ..] m)

-- | Distribución después de n pasos, partiendo de v0.
distribution :: Chain -> Vector -> Int -> Vector
distribution (Chain _ m) v0 n = iterate (`vecMat` m) v0 !! n

-- | Distribución estacionaria: se itera desde la uniforme hasta que
-- dos pasos consecutivos casi no cambian (con tope de 100000 pasos).
stationary :: Chain -> Vector
stationary (Chain names m) = converge (take 100000 (iterate lazy start))
  where
    k     = length names
    start = replicate k (1 / fromIntegral k)
    lazy v = zipWith (\a b -> (a + b) / 2) v (vecMat v m)

converge :: [Vector] -> Vector
converge (x : y : rest)
  | maxDiff x y < tolerance = y
  | otherwise               = converge (y : rest)
converge xs = last xs

maxDiff :: Vector -> Vector -> Double
maxDiff x y = maximum (zipWith (\a b -> abs (a - b)) x y)