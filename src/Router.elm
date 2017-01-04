module Router exposing (..)

import Navigation exposing (Location)
import UrlParser as Url exposing ((</>))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (ContextUpdate(..), Context, Translations)
import Routes exposing (Route(..))
import Home
import Settings


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


routeParser : Url.Parser (Route -> a) a
routeParser =
    Url.oneOf
        [ Url.map HomeRoute Url.top
        , Url.map SettingsRoute (Url.s "settings")
        ]


parseLocation : Location -> Route
parseLocation location =
    location
        |> Url.parseHash routeParser
        |> Maybe.withDefault NotFoundRoute


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
            ( { model | route = route }
            , Cmd.none
            , NoUpdate
            )

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
        , nav [ style [ ( "background-color", "silver" ) ] ]
            [ button [ onClick (NavigateTo HomeRoute) ] [ text "Home" ]
            , button [ onClick (NavigateTo SettingsRoute) ] [ text "Settings" ]
            ]
        , pageView context model
        ]


pageView : Context -> Model -> Html Msg
pageView context model =
    case model.route of
        HomeRoute ->
            Home.view context model.homeModel
                |> Html.map HomeMsg

        SettingsRoute ->
            Settings.view context model.settingsModel
                |> Html.map SettingsMsg

        NotFoundRoute ->
            h1 [] [ text "404 :(" ]
