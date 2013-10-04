{-# LANGUAGE OverloadedStrings #-}
module Network.HTTP.Client.RequestParserSpec where

import           Network.HTTP.Client.Connection
import           Network.HTTP.Client.RequestParser
import           Network.HTTP.Client.Types
import           Network.HTTP.Types
import           Test.Hspec

main :: IO ()
main = hspec spec

spec :: Spec
spec = describe "RequestParserSpec" $ do
    it "simple response" $ do
        let input =
                [ "HTTP/"
                , "1.1 200"
                , " OK\r\nfoo"
                , ": bar\r\n"
                , "baz:bin\r\n\r"
                , "\nignored"
                ]
        (connection, getOutput, getInput) <- dummyConnection input
        statusHeaders <- parseStatusHeaders connection
        statusHeaders `shouldBe` StatusHeaders status200 (HttpVersion 1 1)
            [ ("foo", "bar")
            , ("baz", "bin")
            ]
