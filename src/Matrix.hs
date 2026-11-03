module Matrix (vecMat) where

import Data.List (transpose)
import Types

-- | Producto punto de dos vectores.
dot :: Vector -> Vector -> Double
dot xs ys = sum (zipWith (*) xs ys)

-- | Vector fila por matriz: el componente j es el producto punto
-- del vector con la columna j.
vecMat :: Vector -> Matrix -> Vector
vecMat v m = map (dot v) (transpose m)