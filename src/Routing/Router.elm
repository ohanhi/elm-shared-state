module Routing.Router exposing (..)

import Navigation exposing (Location)
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (..)
import Types exposing (ContextUpdate(..), Context, Translations)
import Routing.Helpers exposing (Route(..), parseLocation, reverseRoute)
import Styles exposing (..)
import Pages.Home as Home
import Pages.Settings as Settings


type alias Model =
    { homeModel : Home.Model
    , settingsModel : Settings.Model
    , route : Route
    }


type Msg
    = UrlChange Location
    | NavigateTo Route
    | HomeMsg Home.Msg
    | SettingsMsg Settings.Msg


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( homeModel, homeCmd ) =
            Home.init

        settingsModel =
            Settings.initModel
    in
        ( { homeModel = homeModel
          , settingsModel = settingsModel
          , route = parseLocation location
          }
        , Cmd.map HomeMsg homeCmd
        )


update : Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update msg model =
    case msg of
        UrlChange location ->
            ( { model | route = parseLocation location }
            , Cmd.none
            , NoUpdate
            )

        NavigateTo route ->
            ( model
            , Navigation.newUrl (reverseRoute route)
            , NoUpdate
            )

        HomeMsg homeMsg ->
            updateHome model homeMsg

        SettingsMsg settingsMsg ->
            updateSettings model settingsMsg


updateHome : Model -> Home.Msg -> ( Model, Cmd Msg, ContextUpdate )
updateHome model homeMsg =
    let
        ( nextHomeModel, homeCmd ) =
            Home.update homeMsg model.homeModel
    in
        ( { model | homeModel = nextHomeModel }
        , Cmd.map HomeMsg homeCmd
        , NoUpdate
        )


updateSettings : Model -> Settings.Msg -> ( Model, Cmd Msg, ContextUpdate )
updateSettings model settingsMsg =
    let
        ( nextSettingsModel, settingsCmd, ctxUpdate ) =
            Settings.update settingsMsg model.settingsModel
    in
        ( { model | settingsModel = nextSettingsModel }
        , Cmd.map SettingsMsg settingsCmd
        , ctxUpdate
        )


view : Context -> Model -> Html Msg
view context model =
    let
        buttonStyles route =
            if model.route == route then
                styles navigationButtonActive
            else
                styles navigationButton
    in
        div [ styles (appStyles ++ wrapper) ]
            [ header [ styles headerSection ]
                [ h1 [] [ text (context.translate "site-title") ]
                ]
            , nav [ styles navigationBar ]
                [ button
                    [ onClick (NavigateTo HomeRoute)
                    , buttonStyles HomeRoute
                    ]
                    [ text (context.translate "page-title-home") ]
                , button
                    [ onClick (NavigateTo SettingsRoute)
                    , buttonStyles SettingsRoute
                    ]
                    [ text (context.translate "page-title-settings") ]
                ]
            , pageView context model
            , footer [ styles footerSection ]
                [ text (context.translate "footer-github-before" ++ " ")
                , a
                    [ href "https://github.com/ohanhi/elm-context-pattern"
                    , styles footerLink
                    ]
                    [ text "Github" ]
                , text (context.translate "footer-github-after")
                ]
            ]


pageView : Context -> Model -> Html Msg
pageView context model =
    div [ styles activeView ]
        [ (case model.route of
            HomeRoute ->
                Home.view context model.homeModel
                    |> Html.map HomeMsg

            SettingsRoute ->
                Settings.view context model.settingsModel
                    |> Html.map SettingsMsg

            NotFoundRoute ->
                h1 [] [ text "404 :(" ]
          )
        ]
