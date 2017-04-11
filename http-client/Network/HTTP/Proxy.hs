{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}
module Network.HTTP.Proxy(  ProxyProtocol(..), EnvHelper(..),
                            systemProxyHelper,
                            httpProtocol,
                            ProxySettings ) where

import           Control.Applicative         ((<$>), (<|>))
import           Control.Arrow               (first)
import           Control.Monad               (guard)
import qualified Data.ByteString.Char8       as S8
import           Data.Char                   (toLower)
import qualified Data.Map                    as Map
import qualified Data.Text                   as T
import           Data.Text.Read              (decimal)
import           Network.HTTP.Client.Request (applyBasicProxyAuth,
                                              extractBasicAuthInfo)
import           Network.HTTP.Client.Types   (HttpExceptionContent (..),
                                              Proxy (..), Request (..),
                                              throwHttp)
import qualified Network.URI                 as U
import           System.Environment          (getEnvironment)

type EnvName     = T.Text
type HostAddress = S8.ByteString
type UserName    = S8.ByteString
type Password    = S8.ByteString

-- There are other proxy protocols like SOCKS, FTP, etc.
data ProxyProtocol = HTTPProxy | HTTPSProxy deriving Show

data ProxySettings = ProxySettings { proxyHost :: Proxy,
                                     proxyAuth :: Maybe (UserName, Password) }

httpProtocol :: Bool -> ProxyProtocol
httpProtocol True  = HTTPSProxy
httpProtocol False = HTTPProxy

data EnvHelper = EHFromRequest
               | EHNoProxy
               | EHUseProxy Proxy

headJust :: [Maybe a] -> Maybe a
headJust []               = Nothing
headJust (Nothing:xs)     = headJust xs
headJust ((y@(Just x)):_) = y

systemProxyHelper :: ProxyProtocol -> EnvHelper -> IO (Request -> Request)
systemProxyHelper prot eh = do
    modifier <- envHelper . envName $ prot

-- Under Windows try first env. variables override then Windows proxy settings
#if defined(WIN32)
    modifier' <- systemProxy prot
    let modifiers = [modifier, modifier']
#else
    let modifiers = [modifier]
#endif

    let chooseMod :: Request -> Maybe ProxySettings
        chooseMod req = headJust . map (\m -> m . host $ req) $ modifiers

        noEnvProxy = case eh of
            EHFromRequest -> id
            EHNoProxy     -> \req -> req { proxy = Nothing }
            EHUseProxy p  -> \req -> req { proxy = Just p  }

    let result req = toRequest . chooseMod $ req where
            toRequest Nothing                            = noEnvProxy req
            toRequest (Just (ProxySettings p muserpass)) = maybe id (uncurry applyBasicProxyAuth) muserpass
                                        req { proxy = Just p }
    pure result


#if defined(WIN32)
-- Extract proxy settings from Windows registry. This is a standard way in Windows OS.
systemProxy :: ProxyProtocol -> IO (HostAddress -> Maybe ProxySettings)
systemProxy = undefined
#endif

envName :: ProxyProtocol -> EnvName
envName HTTPProxy  = "http_proxy"
envName HTTPSProxy = "https_proxy"

-- Extract proxy settings from environment variables. This is a standard way in Linux.
envHelper :: EnvName -> IO (HostAddress -> Maybe ProxySettings)
envHelper name = do
  env <- getEnvironment
  let lenv = Map.fromList $ map (first $ T.toLower . T.pack) env
      lookupEnvVar n = lookup (T.unpack n) env <|> Map.lookup n lenv
      noProxyDomains = domainSuffixes (lookupEnvVar "no_proxy")

  case lookupEnvVar name of
      Nothing  -> return . const $ Nothing
      Just ""  -> return . const $ Nothing
      Just str -> do
          let invalid = throwHttp $ InvalidProxyEnvironmentVariable name (T.pack str)
          (p, muserpass) <- maybe invalid return $ do
              let allowedScheme x = x == "http:"
              uri <- case U.parseURI str of
                  Just u | allowedScheme (U.uriScheme u) -> return u
                  _      -> U.parseURI $ "http://" ++ str

              guard $ allowedScheme $ U.uriScheme uri
              guard $ null (U.uriPath uri) || U.uriPath uri == "/"
              guard $ null $ U.uriQuery uri
              guard $ null $ U.uriFragment uri

              auth <- U.uriAuthority uri
              port' <-
                  case U.uriPort auth of
                      "" -> Just 80
                      ':':rest ->
                          case decimal $ T.pack rest of
                              Right (p, "") -> Just p
                              _             -> Nothing
                      _ -> Nothing

              Just (Proxy (S8.pack $ U.uriRegName auth) port', extractBasicAuthInfo uri)
          return $ \hostRequest ->
              if hostRequest `hasDomainSuffixIn` noProxyDomains
              then Nothing
              else Just $ ProxySettings p muserpass
  where prefixed s | S8.head s == '.' = s
                   | otherwise = S8.cons '.' s
        domainSuffixes Nothing = []
        domainSuffixes (Just "") = []
        domainSuffixes (Just no_proxy) = [prefixed $ S8.dropWhile (== ' ') suffix | suffix <- S8.split ',' (S8.pack (map toLower no_proxy)), not (S8.null suffix)]
        hasDomainSuffixIn host' = any (`S8.isSuffixOf` prefixed (S8.map toLower host'))
