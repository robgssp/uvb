{-# LANGUAGE OverloadedStrings #-}
import Network.DNS
import Network
import Control.Monad
import qualified Data.ByteString.Char8 as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle
import System.Environment

-- For ross's shitty non-pipelining server

main = do
  [host, port] <- getArgs
  rs <- makeResolvSeed defaultResolvConf
  Right (ip:_) <- withResolver rs $ \resolv -> lookupA resolv (B.pack host)
  let ips = show ip
  sh <- connectTo ips $ PortNumber $ fromIntegral $ read port
  B.hPutStr sh "POST /register/robgssp HTTP/1.1\r\n\r\n"
  forM_ [(0::Int)..] $ \_ -> forkIO (attack ips (fromIntegral (read port)))
  forever (threadDelay maxBound)

attack host port = do
  sh <- connectTo host $ PortNumber port
  B.hPutStr sh prepmsg
  putStrLn "hit"
  B.hGet sh 1024
  return ()

prepmsg :: B.ByteString
prepmsg = "POST /robgssp HTTP/1.1\r\n\r\n"
