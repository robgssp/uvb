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
  forkIO $ do
    let sz = 1024*1024
    buf <- mallocBytes sz
    forever $ do hGetBuf sh buf sz >> return () 
  forever $ B.hPutStr sh "POST /robgssp HTTP/1.1\n\n"
  
