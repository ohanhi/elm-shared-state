module Decoders exposing (..)

import Json.Decode
import Json.Decode.Pipeline
import Types exposing (..)


decodePost : Json.Decode.Decoder Post
decodePost =
    Json.Decode.Pipeline.decode Post
        |> Json.Decode.Pipeline.required "userName" Json.Decode.string
        |> Json.Decode.Pipeline.required "id" Json.Decode.int
        |> Json.Decode.Pipeline.required "timestamp" Json.Decode.float
        |> Json.Decode.Pipeline.required "body" Json.Decode.string


decodePostList : Json.Decode.Decoder (List Post)
decodePostList =
    Json.Decode.list decodePost
