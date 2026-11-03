module Types
  ( Vector
  , Matrix
  , Chain (..)
  ) where

-- | Distribución de probabilidad: un valor por estado.
type Vector = [Double]

-- | Matriz por filas: la fila i son las probabilidades de salir del estado i.
type Matrix = [[Double]]

-- | Cadena de Markov: nombres de estados y matriz de transición.
-- El estado i corresponde a la fila i y a la columna i.
data Chain = Chain
  { chainStates :: [String]
  , chainMatrix :: Matrix
  } deriving (Show, Eq)