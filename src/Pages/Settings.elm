module Pages.Settings exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import WebData exposing (WebData(..))
import Dict
import I18n
import WebData.Http
import Styles exposing (..)
import Types exposing (Language(..), Taco, TacoUpdate(..), Translations)
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


update : Msg -> Model -> ( Model, Cmd Msg, TacoUpdate )
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


view : Taco -> Model -> Html Msg
view taco model =
    div []
        [ h2 [] [ text (I18n.get taco.translations "language-selection-heading") ]
        , selectionButton model English "English"
        , selectionButton model FinnishFormal "Suomi (virallinen)"
        , selectionButton model Finnish "Suomi (puhekieli)"
        , h2 [] [ text (I18n.get taco.translations "current-taco-heading") ]
        , currentTacoView taco
        ]


currentTacoView : Taco -> Html never
currentTacoView taco =
    div [ styles card ]
        [ h4 [ styles monospaceFont ] [ text "currentTime" ]
        , pre [] [ text (toString taco.currentTime) ]
        , h4 [ styles monospaceFont ] [ text "translations" ]
        , table [ styles tacoTable ] (List.map translationRow (Dict.toList taco.translations))
        ]


translationRow : ( String, String ) -> Html never
translationRow ( key, value ) =
    tr []
        [ td [ styles tableCell ] [ text key ]
        , td [ styles tableCell ] [ text value ]
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
