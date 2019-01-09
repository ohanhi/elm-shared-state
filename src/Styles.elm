module Styles exposing (actionButton, actionButtonActive, activeView, appStyles, avatarPicture, buttonBase, card, colorLightGrey, colorLightSharedState, colorLighten, colorOffWhite, colorSalsa, colorSharedState, colorText, commitList, container, defaultShadow, flex1, flex2, flexContainer, footerLink, footerSection, gutterRight, gutterTop, headerSection, monospaceFont, navigationBar, navigationButton, navigationButtonActive, navigationButtonBase, rem, sharedStateTable, stargazerName, styles, tableCell, wrapper)

import Css exposing (..)
import Html.Styled as Html exposing (Attribute)
import Html.Styled.Attributes as Attributes


rem : Float -> Rem
rem =
    Css.rem


styles : List Style -> Attribute msg
styles =
    Attributes.css



-- CONSTANTS


colorLightGrey : Color
colorLightGrey =
    hex "e7e7e7"


colorOffWhite : Color
colorOffWhite =
    hex "fffef5"


colorLighten : Color
colorLighten =
    rgba 255 255 255 0.8


colorText : Color
colorText =
    hex "731c0d"


colorSalsa : Color
colorSalsa =
    hex "ff6347"


colorSharedState : Color
colorSharedState =
    hex "fff080"


colorLightSharedState : Color
colorLightSharedState =
    hex "fff9cc"


defaultShadow : Style
defaultShadow =
    boxShadow4 (px 0) (px 2) (px 6) (rgba 0 0 0 0.1)



-- MIXINS


container : List Style
container =
    [ padding2 (rem 0.5) (rem 1) ]


buttonBase : List Style
buttonBase =
    [ fontSize (rem 1)
    , padding2 (rem 0.5) (rem 1)
    , borderStyle none
    , outline none
    , cursor pointer
    ]


navigationButtonBase : List Style
navigationButtonBase =
    [ displayFlex
    , flex (int 1)
    , outline none
    , borderStyle none
    , fontSize (rem 1)
    , padding3 (rem 1) (rem 1) (rem 0.5)
    , cursor pointer
    , fontWeight bold
    , justifyContent center
    ]



-- ELEMENT STYLES


appStyles : List Style
appStyles =
    [ color colorText
    ]


wrapper : List Style
wrapper =
    [ maxWidth (px 720)
    , margin auto
    ]


headerSection : List Style
headerSection =
    container ++ [ textAlign center ]


navigationBar : List Style
navigationBar =
    [ displayFlex
    , flexDirection row
    , backgroundColor colorSharedState
    ]


navigationButton : List Style
navigationButton =
    navigationButtonBase
        ++ [ color colorText
           , backgroundColor colorLightSharedState
           ]


navigationButtonActive : List Style
navigationButtonActive =
    navigationButtonBase
        ++ [ color colorText
           , backgroundColor colorOffWhite
           ]


activeView : List Style
activeView =
    container
        ++ [ backgroundColor colorOffWhite
           , paddingBottom (rem 1)
           ]


actionButton : List Style
actionButton =
    buttonBase
        ++ [ backgroundColor transparent
           , color colorSalsa
           , border3 (px 2) solid colorSalsa
           , borderRadius (px 4)
           , defaultShadow
           ]


actionButtonActive : List Style
actionButtonActive =
    buttonBase
        ++ [ backgroundColor colorSalsa
           , color colorOffWhite
           , border3 (px 2) solid colorSalsa
           , borderRadius (px 4)
           , defaultShadow
           ]


commitList : List Style
commitList =
    [ listStyle none
    , padding (px 0)
    ]


card : List Style
card =
    [ padding2 (rem 0.5) (rem 1)
    , marginBottom (rem 1)
    , borderLeft3 (px 5) solid colorSalsa
    , backgroundColor colorLighten
    , defaultShadow
    ]


footerSection : List Style
footerSection =
    container
        ++ [ textAlign center
           , backgroundColor colorSalsa
           , color colorOffWhite
           , marginBottom (rem 2)
           ]


footerLink : List Style
footerLink =
    [ color colorOffWhite ]


gutterTop : List Style
gutterTop =
    [ marginTop (rem 1) ]


gutterRight : List Style
gutterRight =
    [ marginRight (rem 1) ]


flexContainer : List Style
flexContainer =
    [ displayFlex ]


flex1 : List Style
flex1 =
    [ flex (int 1) ]


flex2 : List Style
flex2 =
    [ flex (int 2) ]


avatarPicture : List Style
avatarPicture =
    [ width (px 50)
    , height (px 50)
    ]


stargazerName : List Style
stargazerName =
    [ paddingLeft (rem 0.5)
    , boxSizing borderBox
    , color colorText
    , displayFlex
    , alignItems center
    ]


sharedStateTable : List Style
sharedStateTable =
    [ property "border-collapse" "collapse"
    , fontFamily monospace
    ]


tableCell : List Style
tableCell =
    [ border3 (px 1) solid colorSharedState
    , padding2 (rem 0.5) (rem 1)
    ]


monospaceFont : List Style
monospaceFont =
    [ fontFamily monospace ]
