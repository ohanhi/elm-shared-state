module Decoders exposing (..)

import Date exposing (Date)
import Json.Decode exposing (Decoder, field, at, string, int, float, dict)
import Json.Decode.Pipeline exposing (decode, required, requiredAt)
import Types exposing (..)


decodeTranslations : Decoder Translations
decodeTranslations =
    dict string


decodeCommit : Decoder Commit
decodeCommit =
    decode Commit
        |> requiredAt [ "commit", "author", "name" ] string
        |> requiredAt [ "sha" ] string
        |> requiredAt [ "commit", "author", "date" ] dateDecoder
        |> requiredAt [ "commit", "message" ] string


dateDecoder : Decoder Date
dateDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\text ->
                case Date.fromString text of
                    Ok date ->
                        Json.Decode.succeed date

                    Err e ->
                        Json.Decode.fail e
            )


decodeCommitList : Decoder (List Commit)
decodeCommitList =
    Json.Decode.list decodeCommit


decodeStargazer : Decoder Stargazer
decodeStargazer =
    decode Stargazer
        |> required "login" string
        |> required "avatar_url" string


decodeStargazerList : Decoder (List Stargazer)
decodeStargazerList =
    Json.Decode.list decodeStargazer
