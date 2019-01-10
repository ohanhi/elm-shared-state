module Types exposing (Commit, Language(..), Stargazer, Translations)

import Dict exposing (Dict)
import Iso8601
import Json.Decode exposing (Decoder, at, dict, field, float, int, string, succeed)
import Json.Decode.Pipeline exposing (required, requiredAt)
import Time exposing (Posix)


type Language
    = English
    | Finnish
    | FinnishFormal


type alias Translations =
    Dict String String


decodeTranslations : Decoder Translations
decodeTranslations =
    dict string


type alias Commit =
    { userName : String
    , sha : String
    , date : Posix
    , message : String
    }


decodeCommit : Decoder Commit
decodeCommit =
    succeed Commit
        |> requiredAt [ "commit", "author", "name" ] string
        |> requiredAt [ "sha" ] string
        |> requiredAt [ "commit", "author", "date" ] Iso8601.decoder
        |> requiredAt [ "commit", "message" ] string


decodeCommitList : Decoder (List Commit)
decodeCommitList =
    Json.Decode.list decodeCommit


type alias Stargazer =
    { login : String
    , avatarUrl : String
    , url : String
    }


decodeStargazer : Decoder Stargazer
decodeStargazer =
    succeed Stargazer
        |> required "login" string
        |> required "avatar_url" string
        |> required "html_url" string


decodeStargazerList : Decoder (List Stargazer)
decodeStargazerList =
    Json.Decode.list decodeStargazer
