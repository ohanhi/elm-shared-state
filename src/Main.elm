module Main exposing (AppState(..), Flags, Model, Msg(..), init, main, update, updateRouter, updateSharedState, updateTime, updateTranslations, view)

import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Decoders
import Html exposing (..)
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http as Http
import Routing.Router as Router
import Time exposing (Posix)
import Types exposing (SharedState, SharedStateUpdate(..), Translations)
import Url exposing (Url)


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , onUrlChange = UrlChange
        , onUrlRequest = LinkClicked
        , subscriptions = \_ -> Time.every 1000 TimeChange
        }


type alias Model =
    { appState : AppState
    , navKey : Browser.Navigation.Key
    , url : Url
    }


type alias Flags =
    { currentTime : Int
    }


type AppState
    = NotReady Posix
    | Ready SharedState Router.Model


type Msg
    = UrlChange Url
    | LinkClicked UrlRequest
    | TimeChange Posix
    | HandleTranslationsResponse (WebData Translations)
    | RouterMsg Router.Msg


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { appState = NotReady (Time.millisToPosix flags.currentTime)
      , url = url
      , navKey = navKey
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

        UrlChange url ->
            updateRouter { model | url = url } (Router.UrlChange url)

        RouterMsg routerMsg ->
            updateRouter model routerMsg

        LinkClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Browser.Navigation.pushUrl model.navKey (Url.toString url) )

                External url ->
                    ( model, Browser.Navigation.load url )


updateTime : Model -> Posix -> ( Model, Cmd Msg )
updateTime model time =
    case model.appState of
        NotReady _ ->
            ( { model | appState = NotReady time }
            , Cmd.none
            )

        Ready sharedState routerModel ->
            ( { model | appState = Ready (updateSharedState sharedState (UpdateTime time)) routerModel }
            , Cmd.none
            )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready sharedState routerModel ->
            let
                nextSharedState =
                    updateSharedState sharedState sharedStateUpdate

                ( nextRouterModel, routerCmd, sharedStateUpdate ) =
                    Router.update sharedState routerMsg routerModel
            in
            ( { model | appState = Ready nextSharedState nextRouterModel }
            , Cmd.map RouterMsg routerCmd
            )

        NotReady _ ->
            Debug.todo "Ooops. We got a sub-component message even though it wasn't supposed to be initialized?!?!?"


updateTranslations : Model -> WebData Translations -> ( Model, Cmd Msg )
updateTranslations model webData =
    case webData of
        Failure _ ->
            Debug.todo "OMG CANT EVEN DOWNLOAD."

        Success translations ->
            case model.appState of
                NotReady time ->
                    let
                        initSharedState =
                            { navKey = model.navKey
                            , currentTime = time
                            , translations = translations
                            }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.url
                    in
                    ( { model | appState = Ready initSharedState initRouterModel }
                    , Cmd.map RouterMsg routerCmd
                    )

                Ready sharedState routerModel ->
                    ( { model | appState = Ready (updateSharedState sharedState (UpdateTranslations translations)) routerModel }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )


updateSharedState : SharedState -> SharedStateUpdate -> SharedState
updateSharedState sharedState sharedStateUpdate =
    case sharedStateUpdate of
        UpdateTime time ->
            { sharedState | currentTime = time }

        UpdateTranslations translations ->
            { sharedState | translations = translations }

        NoUpdate ->
            sharedState


view : Model -> Browser.Document Msg
view model =
    case model.appState of
        Ready sharedState routerModel ->
            Router.view RouterMsg sharedState routerModel

        NotReady _ ->
            { title = "Loading"
            , body = [ text "Loading" ]
            }
