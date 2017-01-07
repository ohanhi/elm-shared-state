module Home exposing (..)

import Date exposing (Date)
import WebData exposing (WebData(..))
import WebData.Http
import Html exposing (..)
import Html.Events exposing (..)
import Styles exposing (..)
import Types exposing (ContextUpdate(..), Context, Commit)
import Decoders


type alias Model =
    { commits : WebData (List Commit)
    }


type Msg
    = HandleCommits (WebData (List Commit))
    | ReloadCommits


init : ( Model, Cmd Msg )
init =
    ( { commits = Loading
      }
    , fetchCommits
    )


fetchCommits : Cmd Msg
fetchCommits =
    WebData.Http.getWithCache
        "https://api.github.com/repos/ohanhi/elm-context-pattern/commits"
        HandleCommits
        Decoders.decodeCommitList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReloadCommits ->
            ( { model | commits = Loading }
            , fetchCommits
            )

        HandleCommits webData ->
            ( { model | commits = webData }
            , Cmd.none
            )


view : Context -> Model -> Html Msg
view context model =
    div []
        [ h2 []
            [ text
                (context.translate "commits-heading"
                    ++ " "
                    ++ "ohanhi/elm-context-pattern"
                )
            ]
        , div []
            [ button
                [ onClick ReloadCommits
                , styles actionButton
                ]
                [ text ("↻ " ++ context.translate "commits-refresh") ]
            ]
        , div [ styles gutterTop ]
            [ viewCommits context model ]
        ]


viewCommits : Context -> Model -> Html Msg
viewCommits context model =
    case model.commits of
        Loading ->
            text (context.translate "status-loading")

        Failure _ ->
            text (context.translate "status-network-error")

        Success commits ->
            commits
                |> List.sortBy (\commit -> -(Date.toTime commit.date))
                |> List.map (viewCommit context)
                |> ul []

        _ ->
            text ""


viewCommit : Context -> Commit -> Html Msg
viewCommit context commit =
    li [ styles card ]
        [ h4 [] [ text commit.userName ]
        , em [] [ text (formatTimestamp context commit.date) ]
        , p [] [ text commit.message ]
        ]


formatTimestamp : Context -> Date -> String
formatTimestamp context date =
    let
        minutes =
            floor ((context.currentTime - (Date.toTime date)) / 1000 / 60)
    in
        case minutes of
            0 ->
                context.translate "timeformat-zero-minutes"

            1 ->
                context.translate "timeformat-one-minute-ago"

            n ->
                context.translate "timeformat-n-minutes-ago-before"
                    ++ " "
                    ++ toString n
                    ++ " "
                    ++ context.translate "timeformat-n-minutes-ago-after"
