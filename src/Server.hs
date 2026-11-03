module Server (runServer) where

import Control.Exception (IOException, catch, finally)
import Network.Socket
import System.IO
import System.Random (randomIO)
import Protocol (handleLine)
import Types (Chain)

runServer :: PortNumber -> IO ()
runServer port = withSocketsDo $ do
  sock <- socket AF_INET Stream defaultProtocol
  setSocketOption sock ReuseAddr 1
  bind sock (SockAddrInet port (tupleToHostAddress (127, 0, 0, 1)))
  listen sock 5
  putStrLn ("Servidor escuchando en 127.0.0.1:" ++ show port)
  acceptLoop sock

acceptLoop :: Socket -> IO ()
acceptLoop sock = do
  (conn, _) <- accept sock
  h <- socketToHandle conn ReadWriteMode
  hSetEncoding h utf8
  hSetBuffering h LineBuffering
  (serve h Nothing `catch` onError) `finally` hClose h
  acceptLoop sock

onError :: IOException -> IO ()
onError e = putStrLn ("Conexión interrumpida: " ++ show e)

-- | Una línea de entrada, una línea de salida, hasta que el cliente cierre.
serve :: Handle -> Maybe Chain -> IO ()
serve h mc = do
  eof <- hIsEOF h
  if eof
    then return ()
    else do
      line <- hGetLine h
      seed <- randomIO
      let (mc', reply) = handleLine seed mc line
      hPutStrLn h reply
      serve h mc'