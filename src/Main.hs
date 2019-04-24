{-# LANGUAGE OverloadedStrings #-}

import GHCJS.Marshal(fromJSVal, toJSVal)
import GHCJS.Foreign.Callback (Callback, syncCallback1, syncCallback1', OnBlocked(ContinueAsync))
import Data.JSString (JSString, pack)
import GHCJS.Types (JSVal, jsval)
import JavaScript.Object (create, setProp)

import qualified Control.Exception
import qualified Data.Aeson.Encode.Pretty
import qualified Data.Char
import qualified Data.IORef
import qualified Data.JSString
import qualified Data.Text
import qualified Data.Text.Lazy
import qualified Data.Text.Lazy.Encoding
import qualified Data.Text.Prettyprint.Doc             as Pretty
import qualified Data.Text.Prettyprint.Doc.Render.Text as Pretty
import qualified Dhall.Core
import qualified Dhall.Import
import qualified Dhall.JSON
import qualified Dhall.Parser
import qualified Dhall.Pretty
import qualified Dhall.TypeCheck
import qualified GHCJS.Foreign.Callback

import Control.Exception (Exception, SomeException)
import Data.JSString (JSString)
import GHCJS.Types (JSVal)
import Data.Text (Text)
import GHCJS.Foreign.Callback (Callback)

import Unsafe.Coerce (unsafeCoerce)
import System.IO.Unsafe (unsafePerformIO)

-- "getHello" test:
-- Assigns a haskell callback, getHello,  to a javascript function.
-- The getHello function constructs a javascript object and
-- returns it to the javascript caller.  The "js_getHello" function
-- is callable from javascript.

foreign import javascript unsafe "js_getHello = $1"
    set_getHelloCallback :: Callback a -> IO ()

foreign import javascript unsafe "parsableDhall = $1"
    set_getParsableDhallCallback :: Callback a -> IO ()

getHelloTest = do

    let parsableDhall jv = do
            Just str <- fromJSVal jv
            let inputText = Data.Text.pack str
            case Dhall.Parser.exprFromText "(input)" inputText of
              Left _ -> toJSVal False
              Right _ -> toJSVal True

    parsableDhallCallback <- syncCallback1' parsableDhall
    set_getParsableDhallCallback parsableDhallCallback

    let getHello jv = do
            Just str <- fromJSVal jv
            let inputText = Data.Text.pack str

            computedJSON <- case Dhall.Parser.exprFromText "(input)" inputText of
                Left exception ->
                  return $ "parse exception: " ++ show exception
                Right parsedExpression -> do
                  eitherResolvedExpression <- Control.Exception.try (Dhall.Import.load parsedExpression)
                  return $ case eitherResolvedExpression of
                      Left exception ->
                        "import resolution exception: " ++ show (exception :: SomeException)
                      Right resolvedExpression ->
                          case Dhall.TypeCheck.typeOf resolvedExpression of
                              Left exception ->
                                  "type exception: " ++ show exception
                              Right inferredType ->
                                  case Dhall.JSON.dhallToJSON resolvedExpression of
                                      Left exception ->
                                          "dhallToJSON exception: " ++ show exception
                                      Right value ->
                                          let jsonBytes = Data.Aeson.Encode.Pretty.encodePretty' jsonConfig value in
                                          case Data.Text.Lazy.Encoding.decodeUtf8' jsonBytes of
                                              Left exception ->
                                                  "decodeUTF8 exception: " ++ show exception
                                              Right jsonText ->
                                                  Data.Text.unpack $ Data.Text.Lazy.toStrict jsonText
            o <- create
            setProp "val" (jsval $ pack $ "(get): hello, " ++ computedJSON) o
            return $ jsval o -- accessible from javascript caller.

    getHelloCallback <- syncCallback1' getHello
    set_getHelloCallback getHelloCallback

main = do
    getHelloTest

fixup :: String -> String
fixup = Data.Text.unpack . (Data.Text.replace "\ESC[1;31mError\ESC[0m" "Error") . Data.Text.pack

jsonConfig :: Data.Aeson.Encode.Pretty.Config
jsonConfig =
    Data.Aeson.Encode.Pretty.Config
        { Data.Aeson.Encode.Pretty.confIndent =
            Data.Aeson.Encode.Pretty.Spaces 2
        , Data.Aeson.Encode.Pretty.confCompare =
            compare
        , Data.Aeson.Encode.Pretty.confNumFormat =
            Data.Aeson.Encode.Pretty.Generic
        , Data.Aeson.Encode.Pretty.confTrailingNewline =
            False
        }
