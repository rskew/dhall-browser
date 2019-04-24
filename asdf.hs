{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Control.Exception
import qualified Data.Aeson.Encode.Pretty
import qualified Data.Char
import qualified Data.IORef
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
import Data.Text (Text)

getHello jv = do
    Just str <- fromJSVal jv
    let inputText = Data.Text.pack str

    computedJSON <- return $ show $ Dhall.Parser.exprFromText "(input)" inputText
    --computedJSON <- case Dhall.Parser.exprFromText "(input)" inputText of
        --Left exception ->
        --  return $ "parse exception: " ++ show exception
        --Right parsedExpression ->
          --eitherResolvedExpression <- Control.Exception.try (Dhall.Import.load parsedExpression)
          --return $ case eitherResolvedExpression of
          --    Left exception ->
          --      "import resolution exception: " ++ show (exception :: SomeException)
          --    Right resolvedExpression ->
          --        --case Dhall.TypeCheck.typeOf resolvedExpression of
          --        --    Left exception ->
          --        --        "type exception: " ++ show exception
          --        --    Right inferredType ->
          --        --        --case Dhall.JSON.dhallToJSON resolvedExpression of
          --        --        --    Left exception ->
          --        --        --        "dhallToJSON exception: " ++ show exception
          --        --        --    Right value ->
          --        --        --        --let jsonBytes = Data.Aeson.Encode.Pretty.encodePretty' jsonConfig value in
          --        --        --        --case Data.Text.Lazy.Encoding.decodeUtf8' jsonBytes of
          --        --        --        --    Left exception ->
          --        --        --        --        "decodeUTF8 exception: " ++ show exception
          --        --        --        --    Right jsonText ->
          --        --        --        --        Data.Text.unpack $ Data.Text.Lazy.toStrict jsonText
    return computerJSON

main = do
    line <- getLine
    getHelloi line
    main

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
