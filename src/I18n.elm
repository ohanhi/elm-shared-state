module I18n exposing (..)

import Dict
import Types exposing (..)


get : Translations -> String -> String
get dict key =
    dict
        |> Dict.get key
        |> Maybe.withDefault key
