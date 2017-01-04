module Router exposing (..)

import Navigation exposing (Location)
import Html exposing (..)
import Types exposing (ContextUpdate(..), Context, Translations)
import Home
import Settings


type alias Model =
    { homeModel : Home.Model
    , settingsModel : Settings.Model
    , route : Route
    }


type Msg
    = UrlChange Location
    | HomeMsg Home.Msg
    | SettingsMsg Settings.Msg


type Route
    = HomeRoute
    | SettingsRoute


init : Context -> Location -> ( Model, Cmd Msg )
init context location =
    let
        ( homeModel, homeCmd ) =
            Home.init context

        settingsModel =
            Settings.initModel
    in
        ( { homeModel = homeModel
          , settingsModel = settingsModel
          , route = HomeRoute
          }
        , Cmd.map HomeMsg homeCmd
        )


update : Context -> Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update context msg model =
    case msg of
        UrlChange location ->
            ( { model | route = HomeRoute }, Cmd.none, NoUpdate )

        HomeMsg homeMsg ->
            updateHome context model homeMsg

        SettingsMsg settingsMsg ->
            updateSettings context model settingsMsg


updateHome : Context -> Model -> Home.Msg -> ( Model, Cmd Msg, ContextUpdate )
updateHome context model homeMsg =
    let
        ( nextHomeModel, homeCmd, ctxUpdate ) =
            Home.update context homeMsg model.homeModel
    in
        ( { model | homeModel = nextHomeModel }
        , Cmd.map HomeMsg homeCmd
        , ctxUpdate
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
    div []
        [ h2 [] [ text "Context Pattern Demo" ]
        , pageView context model
        ]


pageView : Context -> Model -> Html Msg
pageView context model =
    div []
        [ Settings.view context model.settingsModel
            |> Html.map SettingsMsg
        , Home.view context model.homeModel
            |> Html.map HomeMsg
        ]
