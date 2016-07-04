{-# LANGUAGE OverloadedStrings #-}
import Test.Hspec
import Network.HTTP.Client
import Network.HTTP.Client.OpenSSL
import Network.HTTP.Client.Internal
import Network.HTTP.Types
import qualified OpenSSL.Session       as SSL

main :: IO ()
main = withOpenSSL $ hspec $ do
    it "make a TLS connection" $ do
        manager <- newManager $ opensslManagerSettings SSL.context
        withResponse (parseRequest_ "https://httpbin.org/status/418") manager $ \res ->
            responseStatus res `shouldBe` status418
