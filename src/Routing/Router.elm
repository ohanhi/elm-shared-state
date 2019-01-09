module Routing.Router exposing (Model, Msg(..), init, pageView, update, updateHome, updateSettings, view)

import Browser
import Browser.Navigation exposing (Key)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (href)
import Html.Styled.Events exposing (..)
import I18n
import Pages.Home as Home
import Pages.Settings as Settings
import Routing.Helpers exposing (Route(..), parseUrl, reverseRoute)
import Styles exposing (..)
import Types exposing (SharedState, SharedStateUpdate(..), Translations)
import Url exposing (Url)


type alias Model =
    { homeModel : Home.Model
    , settingsModel : Settings.Model
    , route : Route
    }


type Msg
    = UrlChange Url
    | NavigateTo Route
    | HomeMsg Home.Msg
    | SettingsMsg Settings.Msg


init : Url -> ( Model, Cmd Msg )
init url =
    let
        ( homeModel, homeCmd ) =
            Home.init

        settingsModel =
            Settings.initModel
    in
    ( { homeModel = homeModel
      , settingsModel = settingsModel
      , route = parseUrl url
      }
    , Cmd.map HomeMsg homeCmd
    )


update : SharedState -> Msg -> Model -> ( Model, Cmd Msg, SharedStateUpdate )
update sharedState msg model =
    case msg of
        UrlChange location ->
            ( { model | route = parseUrl location }
            , Cmd.none
            , NoUpdate
            )

        NavigateTo route ->
            ( model
            , Browser.Navigation.pushUrl sharedState.navKey (reverseRoute route)
            , NoUpdate
            )

        HomeMsg homeMsg ->
            updateHome model homeMsg

        SettingsMsg settingsMsg ->
            updateSettings sharedState model settingsMsg


updateHome : Model -> Home.Msg -> ( Model, Cmd Msg, SharedStateUpdate )
updateHome model homeMsg =
    let
        ( nextHomeModel, homeCmd ) =
            Home.update homeMsg model.homeModel
    in
    ( { model | homeModel = nextHomeModel }
    , Cmd.map HomeMsg homeCmd
    , NoUpdate
    )


updateSettings : SharedState -> Model -> Settings.Msg -> ( Model, Cmd Msg, SharedStateUpdate )
updateSettings sharedState model settingsMsg =
    let
        ( nextSettingsModel, settingsCmd, sharedStateUpdate ) =
            Settings.update sharedState settingsMsg model.settingsModel
    in
    ( { model | settingsModel = nextSettingsModel }
    , Cmd.map SettingsMsg settingsCmd
    , sharedStateUpdate
    )


view : (Msg -> msg) -> SharedState -> Model -> Browser.Document msg
view msgMapper sharedState model =
    let
        buttonStyles route =
            if model.route == route then
                styles navigationButtonActive

            else
                styles navigationButton

        translate =
            I18n.get sharedState.translations

        title =
            case model.route of
                HomeRoute ->
                    "Home"

                SettingsRoute ->
                    "Settings"

                NotFoundRoute ->
                    "404"

        body =
            div [ styles (appStyles ++ wrapper) ]
                [ header [ styles headerSection ]
                    [ h1 [] [ text (translate "site-title") ]
                    ]
                , nav [ styles navigationBar ]
                    [ button
                        [ onClick (NavigateTo HomeRoute)
                        , buttonStyles HomeRoute
                        ]
                        [ text (translate "page-title-home") ]
                    , button
                        [ onClick (NavigateTo SettingsRoute)
                        , buttonStyles SettingsRoute
                        ]
                        [ text (translate "page-title-settings") ]
                    ]
                , pageView sharedState model
                , footer [ styles footerSection ]
                    [ text (translate "footer-github-before" ++ " ")
                    , a
                        [ href "https://github.com/ohanhi/elm-sharedState/"
                        , styles footerLink
                        ]
                        [ text "Github" ]
                    , text (translate "footer-github-after")
                    ]
                ]
    in
    { title = title ++ " - Elm SharedState Demo"
    , body =
        [ body
            |> Html.Styled.toUnstyled
            |> Html.map msgMapper
        ]
    }


pageView : SharedState -> Model -> Html Msg
pageView sharedState model =
    div [ styles activeView ]
        [ case model.route of
            HomeRoute ->
                Home.view sharedState model.homeModel
                    |> Html.Styled.map HomeMsg

            SettingsRoute ->
                Settings.view sharedState model.settingsModel
                    |> Html.Styled.map SettingsMsg

            NotFoundRoute ->
                h1 [] [ text "404 :(" ]
        ]
