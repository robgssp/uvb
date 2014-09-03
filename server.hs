{-# LANGUAGE OverloadedStrings #-}
import Network.Wai.Handler.Warp hiding (register)
import Network.Wai
import Control.Monad
import Network.HTTP.Types
import Text.Blaze.Html.Renderer.Utf8
import Control.Concurrent.STM
import Control.Concurrent.Timer
import Control.Concurrent.Suspend.Lifted
import qualified STMContainers.Map as SM
import qualified Focus as F
import qualified Text.Blaze.Html4.Strict as H
import qualified Data.Text as T

data Score = Score { curr :: !Integer, last :: !Integer, rps :: !Integer }

main = do
  scores <- atomically $ SM.new
  repeatedTimer (rpsTimer scores) (sDelay 1)
  run 8080 $ app scores

app :: SM.Map T.Text Score -> Application
app scores req resp =
  case (pathInfo req, requestMethod req) of
    ([], "GET") -> index scores
    ([name], "POST") -> incscore scores name
    (["register",name], "POST") -> register scores name
    otherwise -> return $ responseLBS status404 [("Content-Type", "text/plain")] "nope"
    >>= resp

index :: SM.Map T.Text Score -> IO Response
index scores = do
  slist <- atomically $ SM.foldM (\lst n -> return $ n:lst) [] scores
  return $ responseLBS status200 [("Content-Type", "text/html")] $
    renderHtml $
      H.html $ H.body $ H.table $ do
        H.tr $ do
          H.th "Name"
          H.th "Score"
          H.th "RPS"
        forM_ slist $ \(name, Score curr last rps) -> H.tr $ do
          H.td $ H.toHtml name
          H.td $ H.toHtml $ show curr
          H.td $ H.toHtml $ show rps

register :: SM.Map T.Text Score -> T.Text -> IO Response
register scores name =
  atomically $ do
    n <- SM.lookup name scores
    case n of
      Nothing -> do
        SM.insert (Score 0 0 0) name scores
        return $ responseLBS status200 [] ""
      Just _ -> return $ responseLBS status400 [("Content-Type","text/plain")] "User already exists"

incscore :: SM.Map T.Text Score -> T.Text -> IO Response
incscore scores name = do
  atomically $ SM.focus (F.adjustM $ \s@(Score { curr = curr }) -> return s { curr = curr+1 }) name scores
  return $ responseLBS status200 [] ""

rpsTimer :: SM.Map T.Text Score -> IO ()
rpsTimer scores =
  atomically $ SM.foldM
  (\_ (k, _) -> SM.focus (F.adjustM (\(Score curr last rps) ->
                                      return $ Score curr curr $ curr-last))
                k
                scores)
  () scores
