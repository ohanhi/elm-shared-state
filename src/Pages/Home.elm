module Pages.Home exposing (..)

import Date exposing (Date)
import WebData exposing (WebData(..))
import WebData.Http
import Html exposing (..)
import Html.Attributes exposing (src)
import Html.Events exposing (..)
import Styles exposing (..)
import Types exposing (TacoUpdate(..), Taco, Commit, Stargazer)
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
        "https://api.github.com/repos/ohanhi/elm-taco-pattern/commits"
        HandleCommits
        Decoders.decodeCommitList


fetchStargazers : Cmd Msg
fetchStargazers =
    WebData.Http.getWithCache
        "https://api.github.com/repos/ohanhi/elm-taco-pattern/stargazers"
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


view : Taco -> Model -> Html Msg
view taco model =
    div []
        [ h2 [] [ text "ohanhi/elm-taco-pattern" ]
        , div []
            [ button
                [ onClick ReloadData
                , styles actionButton
                ]
                [ text ("↻ " ++ taco.translate "commits-refresh") ]
            ]
        , div [ styles (flexContainer ++ gutterTop) ]
            [ div [ styles (flex2 ++ gutterRight) ]
                [ h3 [] [ text (taco.translate "commits-heading") ]
                , viewCommits taco model
                ]
            , div [ styles flex1 ]
                [ h3 [] [ text (taco.translate "stargazers-heading") ]
                , viewStargazers taco model
                ]
            ]
        ]


viewCommits : Taco -> Model -> Html Msg
viewCommits taco model =
    case model.commits of
        Loading ->
            text (taco.translate "status-loading")

        Failure _ ->
            text (taco.translate "status-network-error")

        Success commits ->
            commits
                |> List.sortBy (\commit -> -(Date.toTime commit.date))
                |> List.map (viewCommit taco)
                |> ul [ styles commitList ]

        _ ->
            text ""


viewCommit : Taco -> Commit -> Html Msg
viewCommit taco commit =
    li [ styles card ]
        [ h4 [] [ text commit.userName ]
        , em [] [ text (formatTimestamp taco commit.date) ]
        , p [] [ text commit.message ]
        ]


formatTimestamp : Taco -> Date -> String
formatTimestamp taco date =
    let
        minutes =
            floor ((taco.currentTime - (Date.toTime date)) / 1000 / 60)
    in
        case minutes of
            0 ->
                taco.translate "timeformat-zero-minutes"

            1 ->
                taco.translate "timeformat-one-minute-ago"

            n ->
                taco.translate "timeformat-n-minutes-ago-before"
                    ++ " "
                    ++ toString n
                    ++ " "
                    ++ taco.translate "timeformat-n-minutes-ago-after"


viewStargazers : Taco -> Model -> Html Msg
viewStargazers taco model =
    case model.stargazers of
        Loading ->
            text (taco.translate "status-loading")

        Failure _ ->
            text (taco.translate "status-network-error")

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
