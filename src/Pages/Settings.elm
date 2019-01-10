module Pages.Settings exposing (Model, Msg(..), currentSharedStateView, getTranslations, initModel, selectionButton, translationRow, update, view)

import Browser.Navigation exposing (pushUrl)
import Decoders
import Dict
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import I18n
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Http
import Routing.Helpers exposing (Route(..), reverseRoute)
import SharedState exposing (SharedState, SharedStateUpdate(..))
import Styles exposing (..)
import Time
import Types exposing (Language(..), Translations)


type alias Model =
    { selectedLanguage : Language
    }


type Msg
    = SelectLanguage Language
    | HandleTranslationsResponse (WebData Translations)
    | NavigateTo Route


initModel : Model
initModel =
    { selectedLanguage = English
    }


update : SharedState -> Msg -> Model -> ( Model, Cmd Msg, SharedStateUpdate )
update sharedState msg model =
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

        NavigateTo route ->
            ( model, pushUrl sharedState.navKey (reverseRoute route), NoUpdate )


getTranslations : Language -> Cmd Msg
getTranslations language =
    let
        url =
            case language of
                English ->
                    "./api/en.json"

                Finnish ->
                    "./api/fi.json"

                FinnishFormal ->
                    "./api/fi-formal.json"
    in
    RemoteData.Http.get url HandleTranslationsResponse Decoders.decodeTranslations


view : SharedState -> Model -> Html Msg
view sharedState model =
    let
        t =
            I18n.get sharedState.translations
    in
    div []
        [ h2 [] [ text (t "language-selection-heading") ]
        , selectionButton model English "English"
        , selectionButton model FinnishFormal "Suomi (virallinen)"
        , selectionButton model Finnish "Suomi (puhekieli)"
        , h2 [] [ text (t "navigation-button-heading") ]
        , p [] [ text (t "navigation-button-desc") ]
        , button [ onClick (NavigateTo HomeRoute), css actionButton ]
            [ text (t "page-title-home") ]
        , h2 [] [ text (t "current-sharedState-heading") ]
        , currentSharedStateView sharedState
        ]


currentSharedStateView : SharedState -> Html never
currentSharedStateView sharedState =
    div [ css card ]
        [ h4 [ css monospaceFont ] [ text "currentTime" ]
        , pre [] [ text (String.fromInt (Time.posixToMillis sharedState.currentTime)) ]
        , h4 [ css monospaceFont ] [ text "translations" ]
        , table [ css sharedStateTable ] (List.map translationRow (Dict.toList sharedState.translations))
        ]


translationRow : ( String, String ) -> Html never
translationRow ( key, value ) =
    tr []
        [ td [ css tableCell ] [ text key ]
        , td [ css tableCell ] [ text value ]
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
        [ css buttonStyles
        , onClick (SelectLanguage language)
        ]
        [ text shownName ]
