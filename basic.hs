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
  B.hPutStr sh "POST /register/robgssp HTTP/1.1\r\n\r\n"
  forM_ ([0..98]::[Int]) $ \_ -> forkIO (attack host (fromIntegral (read port)))
  attack1 sh

attack host port = (connectTo host $ PortNumber port) >>= attack1

attack1 sh = do
  forkIO $ do
    -- let sz = 1024*1024
    -- buf <- mallocBytes sz
    -- forever $ hGetBuf sh buf sz >> return ()
    forever $ B.hGet sh (1024*1024)
  forever $ do
    B.hPutStr sh prepmsg
    putStrLn "hit"

prepmsg :: B.ByteString
prepmsg = B.concat $ take 1024 $ repeat "POST /robgssp HTTP/1.1\r\n\r\n"
