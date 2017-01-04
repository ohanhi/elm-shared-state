module Types exposing (..)

import Dict exposing (Dict)
import Date exposing (Date)
import Time exposing (Time)


type alias Translations =
    Dict String String


type alias Context =
    { currentTime : Time
    , translations : Translations
    }


type alias Commit =
    { userName : String
    , sha : String
    , date : Date
    , message : String
    }


type ContextUpdate
    = NoUpdate
    | UpdateTime Time
    | UpdateTranslations Translations


type Language
    = English
    | Finnish
    | FinnishFormal
