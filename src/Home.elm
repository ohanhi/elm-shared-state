module Home exposing (..)

import WebData exposing (WebData(..))
import WebData.Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Types exposing (ContextUpdate(..), Context, Post)
import Decoders
import I18n


type alias Model =
    { inputText : String
    , posts : WebData (List Post)
    }


type Msg
    = Input String
    | HandlePosts (WebData (List Post))


init : Context -> ( Model, Cmd Msg )
init context =
    ( { inputText = ""
      , posts = Loading
      }
    , WebData.Http.get "/api/posts.json" HandlePosts Decoders.decodePostList
    )


update : Context -> Msg -> Model -> ( Model, Cmd Msg, ContextUpdate )
update context msg model =
    case msg of
        Input txt ->
            ( { model | inputText = txt }
            , Cmd.none
            , UpdateUserInput (toString context.currentTime ++ ": " ++ txt)
            )

        HandlePosts webData ->
            ( { model | posts = webData }
            , Cmd.none
            , NoUpdate
            )


view : Context -> Model -> Html Msg
view context model =
    div []
        [ p [] [ text ("Time: " ++ toString context.currentTime) ]
        , p [] [ text ("Input: " ++ model.inputText) ]
        , p [] [ text ("Context says: " ++ context.userInput) ]
        , input
            [ onInput Input
            , value model.inputText
            ]
            []
        , viewPosts context model
        ]


viewPosts : Context -> Model -> Html Msg
viewPosts context model =
    case model.posts of
        Loading ->
            text "Loading some interesting posts"

        Failure _ ->
            text "There was a network error :("

        Success posts ->
            posts
                |> List.sortBy (\post -> -post.timestamp)
                |> List.map (viewPost context)
                |> ul []

        _ ->
            text ""


viewPost : Context -> Post -> Html Msg
viewPost context post =
    li [ class "post" ]
        [ h4 [] [ text post.userName ]
        , em [] [ text (formatTimestamp context post.timestamp) ]
        , p [] [ text post.body ]
        ]


formatTimestamp : Context -> Float -> String
formatTimestamp context time =
    let
        minutes =
            floor ((context.currentTime - time) / 1000 / 60)

        t =
            I18n.get context.translations
    in
        case minutes of
            0 ->
                t "timeformat-zero-minutes"

            1 ->
                t "timeformat-one-minute-ago"

            n ->
                t "timeformat-n-minutes-ago-before"
                    ++ " "
                    ++ toString n
                    ++ " "
                    ++ t "timeformat-n-minutes-ago-after"
