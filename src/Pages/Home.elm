module Pages.Home exposing (..)

import Date exposing (Date)
import WebData exposing (WebData(..))
import WebData.Http
import Html exposing (..)
import Html.Attributes exposing (src)
import Html.Events exposing (..)
import Styles exposing (..)
import Types exposing (ContextUpdate(..), Context, Commit, Stargazer)
import Decoders


type alias Model =
    { commits : WebData (List Commit)
    , stargazers : WebData (List Stargazer)
    }


type Msg
    = HandleCommits (WebData (List Commit))
    | HandleStargazers (WebData (List Stargazer))
    | ReloadData


init : ( Model, Cmd Msg )
init =
    ( { commits = Loading
      , stargazers = Loading
      }
    , fetchData
    )


fetchData : Cmd Msg
fetchData =
    Cmd.batch
        [ fetchCommits
        , fetchStargazers
        ]


fetchCommits : Cmd Msg
fetchCommits =
    WebData.Http.getWithCache
        "https://api.github.com/repos/ohanhi/elm-context-pattern/commits"
        HandleCommits
        Decoders.decodeCommitList


fetchStargazers : Cmd Msg
fetchStargazers =
    WebData.Http.getWithCache
        "https://api.github.com/repos/ohanhi/elm-context-pattern/stargazers"
        HandleStargazers
        Decoders.decodeStargazerList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReloadData ->
            ( { model
                | commits = Loading
                , stargazers = Loading
              }
            , fetchData
            )

        HandleCommits webData ->
            ( { model | commits = webData }
            , Cmd.none
            )

        HandleStargazers webData ->
            ( { model | stargazers = webData }
            , Cmd.none
            )


view : Context -> Model -> Html Msg
view context model =
    div []
        [ h2 [] [ text "ohanhi/elm-context-pattern" ]
        , div []
            [ button
                [ onClick ReloadData
                , styles actionButton
                ]
                [ text ("↻ " ++ context.translate "commits-refresh") ]
            ]
        , div [ styles (flexContainer ++ gutterTop) ]
            [ div [ styles (flex2 ++ gutterRight) ]
                [ h3 [] [ text (context.translate "commits-heading") ]
                , viewCommits context model
                ]
            , div [ styles flex1 ]
                [ h3 [] [ text (context.translate "stargazers-heading") ]
                , viewStargazers context model
                ]
            ]
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
                |> ul [ styles commitList ]

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


viewStargazers : Context -> Model -> Html Msg
viewStargazers context model =
    case model.stargazers of
        Loading ->
            text (context.translate "status-loading")

        Failure _ ->
            text (context.translate "status-network-error")

        Success stargazers ->
            stargazers
                |> List.reverse
                |> List.map viewStargazer
                |> ul [ styles commitList ]

        _ ->
            text ""


viewStargazer : Stargazer -> Html Msg
viewStargazer stargazer =
    li [ styles (card ++ flexContainer) ]
        [ img
            [ styles avatarPicture
            , src stargazer.avatarUrl
            ]
            []
        , p [ styles stargazerName ] [ text stargazer.login ]
        ]
