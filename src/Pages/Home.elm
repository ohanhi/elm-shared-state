module Pages.Home exposing (Model, Msg(..), fetchCommits, fetchData, fetchStargazers, formatTimestamp, get, init, update, view, viewCommit, viewCommits, viewStargazer, viewStargazers)

import DateFormat.Relative
import Decoders
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (href, src)
import Html.Styled.Events exposing (..)
import I18n
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http as Http
import Styles exposing (..)
import Time exposing (Posix)
import Types exposing (Commit, SharedState, SharedStateUpdate(..), Stargazer)


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


get =
    Http.getWithConfig Http.defaultConfig


fetchCommits : Cmd Msg
fetchCommits =
    get "https://api.github.com/repos/ohanhi/elm-taco/commits"
        HandleCommits
        Decoders.decodeCommitList


fetchStargazers : Cmd Msg
fetchStargazers =
    get "https://api.github.com/repos/ohanhi/elm-taco/stargazers"
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


view : SharedState -> Model -> Html Msg
view sharedState model =
    div []
        [ a
            [ styles appStyles
            , href "https://github.com/ohanhi/elm-taco/"
            ]
            [ h2 [] [ text "ohanhi/elm-shared-state" ] ]
        , div []
            [ button
                [ onClick ReloadData
                , styles actionButton
                ]
                [ text ("↻ " ++ I18n.get sharedState.translations "commits-refresh") ]
            ]
        , div [ styles (flexContainer ++ gutterTop) ]
            [ div [ styles (flex2 ++ gutterRight) ]
                [ h3 [] [ text (I18n.get sharedState.translations "commits-heading") ]
                , viewCommits sharedState model
                ]
            , div [ styles flex1 ]
                [ h3 [] [ text (I18n.get sharedState.translations "stargazers-heading") ]
                , viewStargazers sharedState model
                ]
            ]
        ]


viewCommits : SharedState -> Model -> Html Msg
viewCommits sharedState model =
    case model.commits of
        Loading ->
            text (I18n.get sharedState.translations "status-loading")

        Failure _ ->
            text (I18n.get sharedState.translations "status-network-error")

        Success commits ->
            commits
                |> List.sortBy (\commit -> -(Time.posixToMillis commit.date))
                |> List.map (viewCommit sharedState)
                |> ul [ styles commitList ]

        _ ->
            text ""


viewCommit : SharedState -> Commit -> Html Msg
viewCommit sharedState commit =
    li [ styles card ]
        [ h4 [] [ text commit.userName ]
        , em [] [ text (formatTimestamp sharedState commit.date) ]
        , p [] [ text commit.message ]
        ]


formatTimestamp : SharedState -> Posix -> String
formatTimestamp sharedState date =
    let
        timeDiff =
            Time.posixToMillis sharedState.currentTime
                - Time.posixToMillis date
                |> toFloat

        minutes =
            floor (timeDiff / 1000 / 60)

        seconds =
            modBy 60 (floor (timeDiff / 1000))

        translate =
            I18n.get sharedState.translations
    in
    case minutes of
        0 ->
            translate "timeformat-zero-minutes"

        1 ->
            translate "timeformat-one-minute-ago"

        n ->
            translate "timeformat-n-minutes-ago-before"
                ++ " "
                ++ String.fromInt n
                ++ " "
                ++ translate "timeformat-n-minutes-ago-after"
                ++ " (+"
                ++ String.fromInt seconds
                ++ "s)"


viewStargazers : SharedState -> Model -> Html Msg
viewStargazers sharedState model =
    case model.stargazers of
        Loading ->
            text (I18n.get sharedState.translations "status-loading")

        Failure _ ->
            text (I18n.get sharedState.translations "status-network-error")

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
        , a
            [ styles stargazerName
            , href stargazer.url
            ]
            [ text stargazer.login ]
        ]
