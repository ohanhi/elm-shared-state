module Types exposing (Commit, Language(..), SharedState, SharedStateUpdate(..), Stargazer, Translations)

import Browser.Navigation
import Dict exposing (Dict)
import Time exposing (Posix)


type alias Translations =
    Dict String String


type alias SharedState =
    { navKey : Browser.Navigation.Key
    , currentTime : Posix
    , translations : Translations
    }


type alias Commit =
    { userName : String
    , sha : String
    , date : Posix
    , message : String
    }


type alias Stargazer =
    { login : String
    , avatarUrl : String
    , url : String
    }


type SharedStateUpdate
    = NoUpdate
    | UpdateTime Posix
    | UpdateTranslations Translations


type Language
    = English
    | Finnish
    | FinnishFormal
