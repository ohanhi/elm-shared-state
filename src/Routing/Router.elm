module Routing.Router exposing (..)

import Navigation exposing (Location)
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (..)
import Date
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


init : Context -> Location -> ( Model, Cmd Msg )
init context location =
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


update : Context -> Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update context msg model =
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
            updateHome context model homeMsg

        SettingsMsg settingsMsg ->
            updateSettings context model settingsMsg


updateHome : Context -> Model -> Home.Msg -> ( Model, Cmd Msg, ContextUpdate )
updateHome context model homeMsg =
    let
        ( nextHomeModel, homeCmd ) =
            Home.update homeMsg model.homeModel
    in
        ( { model | homeModel = nextHomeModel }
        , Cmd.map HomeMsg homeCmd
        , NoUpdate
        )


updateSettings : Context -> Model -> Settings.Msg -> ( Model, Cmd Msg, ContextUpdate )
updateSettings context model settingsMsg =
    let
        ( nextSettingsModel, settingsCmd, ctxUpdate ) =
            Settings.update context settingsMsg model.settingsModel
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
