module Types exposing (..)

import Time exposing (Time)


type alias Context =
    { currentTime : Time
    , userInput : String
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
