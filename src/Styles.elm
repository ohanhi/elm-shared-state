module Styles exposing (..)

import Html exposing (Attribute)
import Html.Attributes
import Css exposing (..)


rem : Float -> Rem
rem =
    Css.rem



-- HELPERS


styles : List Mixin -> Attribute msg
styles =
    Css.asPairs >> Html.Attributes.style



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


colorTaco : Color
colorTaco =
    hex "fff080"


colorLightTaco : Color
colorLightTaco =
    hex "fff9cc"


defaultShadow : Mixin
defaultShadow =
    boxShadow4 (px 0) (px 2) (px 6) (rgba 0 0 0 0.1)



-- MIXINS


container : Mixin
container =
    mixin
        [ padding2 (rem 0.5) (rem 1) ]


buttonBase : Mixin
buttonBase =
    mixin
        [ fontSize (rem 1)
        , padding2 (rem 0.5) (rem 1)
        , borderStyle none
        , outline none
        , cursor pointer
        ]


navigationButtonBase : Mixin
navigationButtonBase =
    mixin
        [ displayFlex
        , flex (int 1)
        , outline none
        , borderStyle none
        , fontSize (rem 1)
        , padding3 (rem 1) (rem 1) (rem 0.5)
        , cursor pointer
        , fontWeight bold
          -- elm-css has no justify-content support
        , property "justify-content" "center"
        ]



-- ELEMENT STYLES


appStyles : List Mixin
appStyles =
    [ color colorText
    ]


wrapper : List Mixin
wrapper =
    [ maxWidth (px 720)
    , margin auto
    ]


headerSection : List Mixin
headerSection =
    [ container
    , textAlign center
    ]


navigationBar : List Mixin
navigationBar =
    [ displayFlex
    , flexDirection row
    , backgroundColor colorTaco
    ]


navigationButton : List Mixin
navigationButton =
    [ navigationButtonBase
    , color colorText
    , backgroundColor colorLightTaco
    ]


navigationButtonActive : List Mixin
navigationButtonActive =
    [ navigationButtonBase
    , color colorText
    , backgroundColor colorOffWhite
    ]


activeView : List Mixin
activeView =
    [ container
    , backgroundColor colorOffWhite
    , paddingBottom (rem 1)
    ]


actionButton : List Mixin
actionButton =
    [ buttonBase
    , backgroundColor transparent
    , color colorSalsa
    , border3 (px 2) solid colorSalsa
    , borderRadius (px 4)
    , defaultShadow
    ]


actionButtonActive : List Mixin
actionButtonActive =
    [ buttonBase
    , backgroundColor colorSalsa
    , color colorOffWhite
    , border3 (px 2) solid colorSalsa
    , borderRadius (px 4)
    , defaultShadow
    ]


commitList : List Mixin
commitList =
    [ listStyle none
    , padding (px 0)
    ]


card : List Mixin
card =
    [ padding2 (rem 0.5) (rem 1)
    , marginBottom (rem 1)
    , borderLeft3 (px 5) solid colorSalsa
    , backgroundColor colorLighten
    , defaultShadow
    ]


footerSection : List Mixin
footerSection =
    [ container
    , textAlign center
    , backgroundColor colorSalsa
    , color colorOffWhite
    , marginBottom (rem 2)
    ]


footerLink : List Mixin
footerLink =
    [ color colorOffWhite ]


gutterTop : List Mixin
gutterTop =
    [ marginTop (rem 1) ]


gutterRight : List Mixin
gutterRight =
    [ marginRight (rem 1) ]


flexContainer : List Mixin
flexContainer =
    [ displayFlex ]


flex1 : List Mixin
flex1 =
    [ flex (int 1) ]


flex2 : List Mixin
flex2 =
    [ flex (int 2) ]


avatarPicture : List Mixin
avatarPicture =
    [ width (px 50)
    , height (px 50)
    ]


stargazerName : List Mixin
stargazerName =
    [ paddingLeft (rem 0.5)
    , boxSizing borderBox
    , color colorText
    , displayFlex
    , alignItems center
    ]


tacoTable : List Mixin
tacoTable =
    [ property "border-collapse" "collapse"
    , fontFamily monospace
    ]


tableCell : List Mixin
tableCell =
    [ border3 (px 1) solid colorTaco
    , padding2 (rem 0.5) (rem 1)
    ]


monospaceFont : List Mixin
monospaceFont =
    [ fontFamily monospace ]
