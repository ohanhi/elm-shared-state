module Main exposing (..)

import Navigation
import Time exposing (Time)
import Html exposing (..)
import WebData exposing (WebData(..))
import WebData.Http as Http
import Decoders
import Types exposing (ContextUpdate(..), Context, Translations)
import Home
import Settings


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Time.every Time.second TimeChange
        }


type alias Model =
    AppState


type AppState
    = NotReady
    | Ready Context Home.Model Settings.Model


type Msg
    = UrlChange Navigation.Location
    | TimeChange Time
    | HandleTranslationsResponse (WebData Translations)
    | HomeMsg Home.Msg
    | SettingsMsg Settings.Msg


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( NotReady
    , Http.get "./en.json" HandleTranslationsResponse Decoders.decodeTranslations
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimeChange time ->
            updateTime model time

        HomeMsg homeMsg ->
            updateHome model homeMsg

        SettingsMsg settingsMsg ->
            updateSettings model settingsMsg

        HandleTranslationsResponse webData ->
            updateTranslations model webData

        UrlChange location ->
            ( model, Cmd.none )


updateTime : Model -> Time -> ( Model, Cmd Msg )
updateTime model time =
    case model of
        NotReady ->
            ( model, Cmd.none )

        Ready context homeModel settingsModel ->
            ( Ready (updateContext context (UpdateTime time)) homeModel settingsModel
            , Cmd.none
            )


updateHome : Model -> Home.Msg -> ( Model, Cmd Msg )
updateHome model homeMsg =
    case model of
        Ready context homeModel settingsModel ->
            let
                ( nextHomeModel, homeCmd, ctxUpdate ) =
                    Home.update context homeMsg homeModel
            in
                ( Ready (updateContext context ctxUpdate) nextHomeModel settingsModel
                , Cmd.map HomeMsg homeCmd
                )

        NotReady ->
            Debug.crash "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?!?!?"


updateSettings : Model -> Settings.Msg -> ( Model, Cmd Msg )
updateSettings model settingsMsg =
    case model of
        Ready context homeModel settingsModel ->
            let
                ( nextSettingsModel, settingsCmd, ctxUpdate ) =
                    Settings.update context settingsMsg settingsModel
            in
                ( Ready (updateContext context ctxUpdate) homeModel nextSettingsModel
                , Cmd.map SettingsMsg settingsCmd
                )

        NotReady ->
            Debug.crash "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?!?!?"


updateTranslations : Model -> WebData Translations -> ( Model, Cmd Msg )
updateTranslations model webData =
    case webData of
        Failure _ ->
            Debug.crash "OMG CANT EVEN DOWNLOAD."

        Success translations ->
            let
                initContext =
                    { currentTime = 0
                    , userInput = ""
                    , translations = translations
                    }

                ( initHomeModel, homeCmd ) =
                    Home.init initContext

                initSettingsModel =
                    Settings.initModel
            in
                case model of
                    NotReady ->
                        ( Ready initContext initHomeModel initSettingsModel
                        , Cmd.map HomeMsg homeCmd
                        )

                    Ready context homeModel settingsModel ->
                        ( Ready (updateContext context (UpdateTranslations translations)) homeModel settingsModel
                        , Cmd.none
                        )

        _ ->
            ( model, Cmd.none )


updateContext : Context -> ContextUpdate -> Context
updateContext context ctxUpdate =
    case ctxUpdate of
        UpdateUserInput txt ->
            { context | userInput = txt }

        UpdateTime time ->
            { context | currentTime = time }

        UpdateTranslations translations ->
            { context | translations = translations }

        NoUpdate ->
            context


view : Model -> Html Msg
view model =
    case model of
        Ready context homeModel settingsModel ->
            div []
                [ Settings.view context settingsModel
                    |> Html.map SettingsMsg
                , Home.view context homeModel
                    |> Html.map HomeMsg
                ]

        NotReady ->
            text "Loading"
