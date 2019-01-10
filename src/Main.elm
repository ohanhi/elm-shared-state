module Main exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Decoders
import Html exposing (..)
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http as Http
import Routing.Router as Router
import SharedState exposing (SharedState, SharedStateUpdate(..))
import Time exposing (Posix)
import Types exposing (Translations)
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
    { currentTime : Int }


type AppState
    = NotReady Posix
    | Ready SharedState Router.Model
    | FailedToInitialize


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
    , Http.get "./api/en.json" HandleTranslationsResponse Decoders.decodeTranslations
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
            ( { model | appState = Ready (SharedState.update sharedState (UpdateTime time)) routerModel }
            , Cmd.none
            )

        FailedToInitialize ->
            ( model, Cmd.none )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready sharedState routerModel ->
            let
                nextSharedState =
                    SharedState.update sharedState sharedStateUpdate

                ( nextRouterModel, routerCmd, sharedStateUpdate ) =
                    Router.update sharedState routerMsg routerModel
            in
            ( { model | appState = Ready nextSharedState nextRouterModel }
            , Cmd.map RouterMsg routerCmd
            )

        _ ->
            let
                _ =
                    Debug.log "We got a router message even though the app is not ready?"
                        routerMsg
            in
            ( model, Cmd.none )


{-| Translations are the prerequisite for moving from `NotReady` to `Ready`.
This function has all the related logic.
-}
updateTranslations : Model -> WebData Translations -> ( Model, Cmd Msg )
updateTranslations model webData =
    case webData of
        -- If the initial request fails, we simply go to a failure state. In a real application, this case could be handled with e.g. retrying or using a built-in fallback value.
        Failure _ ->
            ( { model | appState = FailedToInitialize }, Cmd.none )

        -- If the translations were successfully loaded, we either:
        --   a) initialize the whole thing, or
        --   b) update the current running application.
        Success translations ->
            case model.appState of
                NotReady time ->
                    -- We don't have a ready app, let's create one now
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
                    -- If we do have an app ready, let's update the sharedState while keeping the routerModel unchanged.
                    ( { model
                        | appState =
                            Ready
                                (SharedState.update sharedState (UpdateTranslations translations))
                                routerModel
                      }
                    , Cmd.none
                    )

                FailedToInitialize ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.appState of
        Ready sharedState routerModel ->
            Router.view RouterMsg sharedState routerModel

        NotReady _ ->
            { title = "Loading"
            , body = [ text "Loading" ]
            }

        FailedToInitialize ->
            { title = "Failure"
            , body = [ text "The application failed to initialize. " ]
            }
