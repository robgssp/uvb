{-# LANGUAGE OverloadedStrings #-}
import Network
import Control.Monad
import qualified Data.ByteString.Char8 as B
import Control.Concurrent
import Foreign.Marshal.Alloc
import GHC.IO.Handle

main = do
  sh <- connectTo "jake.csh.rit.edu" $ PortNumber 8080
  B.hPutStr sh "POST /register/robgssp HTTP/1.1\n\n"
  forM_ ([0..98]::[Int]) $ \_ -> forkIO attack
  attack1 sh

attack = (connectTo "jake.csh.rit.edu" $ PortNumber 8080) >>= attack1

attack1 sh = do
  forkIO $ do
    let sz = 1024*1024
    buf <- mallocBytes sz
    forever $ hGetBuf sh buf sz >> return () 
  forever $ B.hPutStr sh prepmsg

prepmsg :: B.ByteString
prepmsg = B.concat $ take 1024 $ repeat "POST /robgssp HTTP/1.1\n\n"
