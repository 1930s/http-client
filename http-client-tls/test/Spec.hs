{-# LANGUAGE OverloadedStrings #-}
import Test.Hspec
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types

main :: IO ()
main = hspec $ do
    it "make a TLS connection" $ do
        manager <- newManager tlsManagerSettings
        withResponse "https://httpbin.org/status/418" manager $ \res ->
            responseStatus res `shouldBe` status418
