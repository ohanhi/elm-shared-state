module Main exposing (..)

import Navigation exposing (Location)
import Time exposing (Time)
import Html exposing (..)
import WebData exposing (WebData(..))
import WebData.Http as Http
import Decoders
import Types exposing (ContextUpdate(..), Context, Translations)
import Router


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Time.every Time.second TimeChange
        }


type alias Model =
    { appState : AppState
    , location : Location
    }


type AppState
    = NotReady
    | Ready Context Router.Model


type Msg
    = UrlChange Location
    | TimeChange Time
    | HandleTranslationsResponse (WebData Translations)
    | RouterMsg Router.Msg


init : Location -> ( Model, Cmd Msg )
init location =
    ( { appState = NotReady
      , location = location
      }
    , Http.get "/api/en.json" HandleTranslationsResponse Decoders.decodeTranslations
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TimeChange time ->
            updateTime model time

        HandleTranslationsResponse webData ->
            updateTranslations model webData

        UrlChange location ->
            updateRouter { model | location = location } (Router.UrlChange location)

        RouterMsg pageParentMsg ->
            updateRouter model pageParentMsg


updateTime : Model -> Time -> ( Model, Cmd Msg )
updateTime model time =
    case model.appState of
        NotReady ->
            ( model, Cmd.none )

        Ready context pageParentModel ->
            ( { model | appState = Ready (updateContext context (UpdateTime time)) pageParentModel }
            , Cmd.none
            )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model pageParentMsg =
    case model.appState of
        Ready context pageParentModel ->
            let
                ( nextRouterModel, pageParentCmd, ctxUpdate ) =
                    Router.update context pageParentMsg pageParentModel
            in
                ( { model | appState = Ready (updateContext context ctxUpdate) nextRouterModel }
                , Cmd.map RouterMsg pageParentCmd
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
                    , translations = translations
                    }

                ( initRouterModel, pageParentCmd ) =
                    Router.init initContext model.location
            in
                case model.appState of
                    NotReady ->
                        ( { model | appState = Ready initContext initRouterModel }
                        , Cmd.map RouterMsg pageParentCmd
                        )

                    Ready context pageParentModel ->
                        ( { model | appState = Ready (updateContext context (UpdateTranslations translations)) pageParentModel }
                        , Cmd.none
                        )

        _ ->
            ( model, Cmd.none )


updateContext : Context -> ContextUpdate -> Context
updateContext context ctxUpdate =
    case ctxUpdate of
        UpdateTime time ->
            { context | currentTime = time }

        UpdateTranslations translations ->
            { context | translations = translations }

        NoUpdate ->
            context


view : Model -> Html Msg
view model =
    case model.appState of
        Ready context pageParentModel ->
            Router.view context pageParentModel
                |> Html.map RouterMsg

        NotReady ->
            text "Loading"
