module Main exposing (..)

import Navigation exposing (Location)
import Time exposing (Time)
import Html exposing (..)
import WebData exposing (WebData(..))
import WebData.Http as Http
import Decoders
import Types exposing (ContextUpdate(..), Context, Translations)
import Routing.Router as Router
import I18n


main : Program Flags Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Time.every Time.second TimeChange
        }


type alias Model =
    { appState : AppState
    , location : Location
    }


type alias Flags =
    { currentTime : Time
    }


type AppState
    = NotReady Time
    | Ready Context Router.Model


type Msg
    = UrlChange Location
    | TimeChange Time
    | HandleTranslationsResponse (WebData Translations)
    | RouterMsg Router.Msg


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    ( { appState = NotReady flags.currentTime
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

        RouterMsg routerMsg ->
            updateRouter model routerMsg


updateTime : Model -> Time -> ( Model, Cmd Msg )
updateTime model time =
    case model.appState of
        NotReady _ ->
            ( { model | appState = NotReady time }
            , Cmd.none
            )

        Ready context routerModel ->
            ( { model | appState = Ready (updateContext context (UpdateTime time)) routerModel }
            , Cmd.none
            )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready context routerModel ->
            let
                nextContext =
                    updateContext context ctxUpdate

                ( nextRouterModel, routerCmd, ctxUpdate ) =
                    Router.update routerMsg routerModel
            in
                ( { model | appState = Ready nextContext nextRouterModel }
                , Cmd.map RouterMsg routerCmd
                )

        NotReady _ ->
            Debug.crash "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?!?!?"


updateTranslations : Model -> WebData Translations -> ( Model, Cmd Msg )
updateTranslations model webData =
    case webData of
        Failure _ ->
            Debug.crash "OMG CANT EVEN DOWNLOAD."

        Success translations ->
            case model.appState of
                NotReady time ->
                    let
                        initContext =
                            { currentTime = time
                            , translate = I18n.get translations
                            }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.location
                    in
                        ( { model | appState = Ready initContext initRouterModel }
                        , Cmd.map RouterMsg routerCmd
                        )

                Ready context routerModel ->
                    ( { model | appState = Ready (updateContext context (UpdateTranslations translations)) routerModel }
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
            { context | translate = I18n.get translations }

        NoUpdate ->
            context


view : Model -> Html Msg
view model =
    case model.appState of
        Ready context routerModel ->
            Router.view context routerModel
                |> Html.map RouterMsg

        NotReady _ ->
            text "Loading"
