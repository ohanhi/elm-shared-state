module Router exposing (..)

import Navigation exposing (Location)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (ContextUpdate(..), Context, Translations)
import Routes exposing (Route(..))
import Home
import Settings
import I18n


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
          , route = Routes.parseLocation location
          }
        , Cmd.map HomeMsg homeCmd
        )


update : Context -> Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update context msg model =
    case msg of
        UrlChange location ->
            ( { model | route = Routes.parseLocation location }
            , Cmd.none
            , NoUpdate
            )

        NavigateTo route ->
            ( model
            , Navigation.newUrl (Routes.reverseRoute route)
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
        t =
            I18n.get context.translations
    in
        div []
            [ h2 [] [ text (t "site-title") ]
            , nav [ style [ ( "background-color", "silver" ) ] ]
                [ button [ onClick (NavigateTo HomeRoute) ] [ text (t "page-title-home") ]
                , button [ onClick (NavigateTo SettingsRoute) ] [ text (t "page-title-settings") ]
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
