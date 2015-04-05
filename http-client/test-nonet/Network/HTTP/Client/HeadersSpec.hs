{-# LANGUAGE OverloadedStrings #-}
module Network.HTTP.Client.HeadersSpec where

import           Network.HTTP.Client.Internal
import           Network.HTTP.Types
import           Test.Hspec

main :: IO ()
main = hspec spec

spec :: Spec
spec = describe "HeadersSpec" $ do
    it "simple response" $ do
        let input =
                [ "HTTP/"
                , "1.1 200"
                , " OK\r\nfoo"
                , ": bar\r\n"
                , "baz:bin\r\n\r"
                , "\nignored"
                ]
        (connection, _, _) <- dummyConnection input
        statusHeaders <- parseStatusHeaders connection Nothing Nothing
        statusHeaders `shouldBe` StatusHeaders status200 (HttpVersion 1 1)
            [ ("foo", "bar")
            , ("baz", "bin")
            ]
