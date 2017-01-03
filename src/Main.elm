module Main exposing (..)

import Navigation
import Time exposing (Time)
import Html exposing (..)
import WebData exposing (WebData(..))
import WebData.Http as Http
import Decoders
import Types exposing (ContextUpdate(..), Context, Translations)
import Home


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
    | Ready Context Home.Model


type Msg
    = UrlChange Navigation.Location
    | TimeChange Time
    | HandleTranslationsResponse (WebData Translations)
    | HomeMsg Home.Msg


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( NotReady
    , Http.get "./fi.json" HandleTranslationsResponse Decoders.decodeTranslations
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimeChange time ->
            updateTime model time

        HomeMsg homeMsg ->
            updateHome model homeMsg

        HandleTranslationsResponse webData ->
            updateTranslations model webData

        UrlChange location ->
            ( model, Cmd.none )


updateTime : Model -> Time -> ( Model, Cmd Msg )
updateTime model time =
    case model of
        NotReady ->
            ( model, Cmd.none )

        Ready context homeModel ->
            ( Ready (updateContext context (UpdateTime time)) homeModel
            , Cmd.none
            )


updateHome : Model -> Home.Msg -> ( Model, Cmd Msg )
updateHome model homeMsg =
    case model of
        Ready context homeModel ->
            let
                -- TODO
                ( nextHomeModel, homeCmd, ctxUpdate ) =
                    Home.update context homeMsg homeModel
            in
                ( Ready (updateContext context ctxUpdate) nextHomeModel, Cmd.none )

        NotReady ->
            Debug.crash "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?!?!?"


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
            in
                case model of
                    NotReady ->
                        ( Ready initContext initHomeModel
                        , Cmd.map HomeMsg homeCmd
                        )

                    Ready context homeModel ->
                        ( Ready (updateContext context (UpdateTranslations translations)) homeModel
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
        Ready context homeModel ->
            Home.view context homeModel
                |> Html.map HomeMsg

        NotReady ->
            text "Loading"
