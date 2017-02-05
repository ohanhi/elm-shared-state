module Main exposing (..)

import Navigation exposing (Location)
import Time exposing (Time)
import Html exposing (..)
import WebData exposing (WebData(..))
import WebData.Http as Http
import Decoders
import Types exposing (TacoUpdate(..), Taco, Translations)
import Routing.Router as Router


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
    | Ready Taco Router.Model


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

        Ready taco routerModel ->
            ( { model | appState = Ready (updateTaco taco (UpdateTime time)) routerModel }
            , Cmd.none
            )


updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready taco routerModel ->
            let
                nextTaco =
                    updateTaco taco tacoUpdate

                ( nextRouterModel, routerCmd, tacoUpdate ) =
                    Router.update routerMsg routerModel
            in
                ( { model | appState = Ready nextTaco nextRouterModel }
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
                        initTaco =
                            { currentTime = time
                            , translations = translations
                            }

                        ( initRouterModel, routerCmd ) =
                            Router.init model.location
                    in
                        ( { model | appState = Ready initTaco initRouterModel }
                        , Cmd.map RouterMsg routerCmd
                        )

                Ready taco routerModel ->
                    ( { model | appState = Ready (updateTaco taco (UpdateTranslations translations)) routerModel }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )


updateTaco : Taco -> TacoUpdate -> Taco
updateTaco taco tacoUpdate =
    case tacoUpdate of
        UpdateTime time ->
            { taco | currentTime = time }

        UpdateTranslations translations ->
            { taco | translations = translations }

        NoUpdate ->
            taco


view : Model -> Html Msg
view model =
    case model.appState of
        Ready taco routerModel ->
            Router.view taco routerModel
                |> Html.map RouterMsg

        NotReady _ ->
            text "Loading"
