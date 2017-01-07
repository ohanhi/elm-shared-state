module Decoders exposing (..)

import Date exposing (Date)
import Json.Decode exposing (Decoder, field, at, string, int, float, dict)
import Types exposing (..)


decodeTranslations : Decoder Translations
decodeTranslations =
    dict string


decodeCommit : Decoder Commit
decodeCommit =
    Json.Decode.map4 Commit
        (at [ "commit", "author", "name" ] Json.Decode.string)
        (at [ "sha" ] Json.Decode.string)
        (at [ "commit", "author", "date" ] dateDecoder)
        (at [ "commit", "message" ] Json.Decode.string)


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
    Json.Decode.map2 Stargazer
        (field "login" string)
        (field "avatar_url" string)


decodeStargazerList : Decoder (List Stargazer)
decodeStargazerList =
    Json.Decode.list decodeStargazer
