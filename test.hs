{-# LANGUAGE OverloadedStrings #-}
import Network.HTTP.Enumerator
import OpenSSL
import Network
import qualified Data.ByteString as S

main :: IO ()
main = withSocketsDo $ withOpenSSL $ do
    (hs, b) <- http $ Request
        { host = "localhost"
        , port = 80
        , secure = False
        , headers = []
        , path = "/"
        , queryString = [("foo", "bar")]
        }
    mapM_ (\(x, y) -> do
        S.putStr x
        putStr ": "
        S.putStr y
        putStrLn "") hs
    putStrLn ""
    S.putStr b
