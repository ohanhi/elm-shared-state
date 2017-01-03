module Types exposing (..)

import Dict exposing (Dict)
import Time exposing (Time)


type alias Translations =
    Dict String String


type alias Context =
    { currentTime : Time
    , userInput : String
    , translations : Translations
    }


type alias Post =
    { userName : String
    , id : Int
    , timestamp : Time
    , body : String
    }


type ContextUpdate
    = NoUpdate
    | UpdateUserInput String
    | UpdateTime Time
    | UpdateTranslations Translations


type Language
    = English
    | Finnish
