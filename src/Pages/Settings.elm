module Pages.Settings exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import WebData exposing (WebData(..))
import WebData.Http
import Styles exposing (..)
import Types exposing (Language(..), Context, ContextUpdate(..), Translations)
import Decoders


type alias Model =
    { selectedLanguage : Language
    }


type Msg
    = SelectLanguage Language
    | HandleTranslationsResponse (WebData Translations)


initModel : Model
initModel =
    { selectedLanguage = English
    }


update : Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update msg model =
    case msg of
        SelectLanguage lang ->
            ( { model | selectedLanguage = lang }
            , getTranslations lang
            , NoUpdate
            )

        HandleTranslationsResponse webData ->
            case webData of
                Success translations ->
                    ( model, Cmd.none, UpdateTranslations translations )

                _ ->
                    ( model, Cmd.none, NoUpdate )


getTranslations : Language -> Cmd Msg
getTranslations language =
    let
        url =
            case language of
                English ->
                    "/api/en.json"

                Finnish ->
                    "/api/fi.json"

                FinnishFormal ->
                    "/api/fi-formal.json"
    in
        WebData.Http.get url HandleTranslationsResponse Decoders.decodeTranslations


view : Context -> Model -> Html Msg
view context model =
    div []
        [ h2 [] [ text (context.translate "language-selection-heading") ]
        , selectionButton model English "English"
        , selectionButton model FinnishFormal "Suomi (virallinen)"
        , selectionButton model Finnish "Suomi (puhekieli)"
        , pre [ styles card ] [ text ("context == " ++ toString context) ]
        ]


selectionButton : Model -> Language -> String -> Html Msg
selectionButton model language shownName =
    let
        buttonStyles =
            if model.selectedLanguage == language then
                actionButtonActive ++ gutterRight
            else
                actionButton ++ gutterRight
    in
        button
            [ styles buttonStyles
            , onClick (SelectLanguage language)
            ]
            [ text shownName ]
