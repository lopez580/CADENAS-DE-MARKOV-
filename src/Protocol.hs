module Protocol (handleLine) where

import Data.Char (isSpace)
import Data.List (elemIndex, intercalate)
import System.Random (mkStdGen)
import Markov
import Simulation
import Types

data Command = Load Chain | Query Query

data Query
  = Simulate String Int
  | Dist String Int
  | Stationary

-- ---------- Entrada ----------

trim :: String -> String
trim = f . f where f = reverse . dropWhile isSpace

splitOn :: Char -> String -> [String]
splitOn d s = case break (== d) s of
  (a, [])       -> [a]
  (a, _ : rest) -> a : splitOn d rest

readDouble :: String -> Either String Double
readDouble s = case reads (trim s) of
  [(x, "")] -> Right x
  _         -> Left ("Número inválido: " ++ trim s)

readNat :: String -> Either String Int
readNat s = case reads s of
  [(n, "")] | n >= 0 -> Right n
  _                  -> Left ("Número de pasos inválido: " ++ s)

parseCommand :: String -> Either String Command
parseCommand line = case words line of
  ("LOAD" : _)       -> parseLoad (drop 4 line)
  ["SIMULATE", s, n] -> Query . Simulate s <$> readNat n
  ["DIST", s, n]     -> Query . Dist s <$> readNat n
  ["STATIONARY"]     -> Right (Query Stationary)
  _                  -> Left "Comando desconocido"

parseLoad :: String -> Either String Command
parseLoad body = case splitOn '|' body of
  [names, rows] -> do
    m <- mapM (mapM readDouble . splitOn ',') (splitOn ';' rows)
    Load <$> validate (Chain (map trim (splitOn ',' names)) m)
  _ -> Left "Formato: LOAD estados | matriz"

-- ---------- Ejecución ----------

stateIndex :: Chain -> String -> Either String Int
stateIndex c s =
  maybe (Left ("Estado desconocido: " ++ s)) Right (elemIndex s (chainStates c))

execute :: Int -> Maybe Chain -> Command -> Either String (Maybe Chain, String)
execute _ _ (Load c) = Right (Just c, okJson [])
execute seed mc (Query q) = case mc of
  Nothing -> Left "Primero carga una cadena con LOAD"
  Just c  -> (\body -> (mc, body)) <$> run seed c q

run :: Int -> Chain -> Query -> Either String String
run seed c (Simulate s n) = do
  i <- stateIndex c s
  let path = simulate c i n (mkStdGen seed)
  Right (okJson [("path", jsonList (map (jsonStr . (chainStates c !!)) path))])
run _ c (Dist s n) = do
  i <- stateIndex c s
  let start = [if j == i then 1 else 0 | j <- [0 .. length (chainStates c) - 1]]
  Right (okJson [("dist", distJson c (distribution c start n))])
run _ c Stationary =
  Right (okJson [("dist", distJson c (stationary c))])

-- ---------- Salida (JSON a mano) ----------

distJson :: Chain -> Vector -> String
distJson c v = obj (zip (chainStates c) (map show v))

okJson :: [(String, String)] -> String
okJson fields = obj (("ok", "true") : fields)

errJson :: String -> String
errJson msg = obj [("ok", "false"), ("error", jsonStr msg)]

obj :: [(String, String)] -> String
obj fs = "{" ++ intercalate "," [jsonStr k ++ ":" ++ v | (k, v) <- fs] ++ "}"

jsonList :: [String] -> String
jsonList xs = "[" ++ intercalate "," xs ++ "]"

jsonStr :: String -> String
jsonStr s = "\"" ++ concatMap esc s ++ "\""
  where
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc ch   = [ch]

-- ---------- Punto de entrada ----------

-- | Procesa una línea: recibe semilla, cadena actual y texto;
-- devuelve la cadena (posiblemente nueva) y la respuesta en JSON.
handleLine :: Int -> Maybe Chain -> String -> (Maybe Chain, String)
handleLine seed mc line =
  case parseCommand (trim line) >>= execute seed mc of
    Left err -> (mc, errJson err)
    Right r  -> r