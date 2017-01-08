# Context Pattern


This repository serves as an example for building larger Single-Page Applications (SPAs) in Elm 0.18. The main focus is what I call _the context pattern_, which can be used to provide some application-wide information to all the modules that need it. In this example we have the current time, as well as translations (I18n) in the context. In a real application, you would likely have the current logged-in user in the context.


## How to try it

There is a live demo here: [https://ohanhi.github.io/elm-context-pattern/](https://ohanhi.github.io/elm-context-pattern/)

To set up on your own computer, you will need `git` and `elm-reactor` 0.18 installed.

Simply clone the repository and start up elm-reactor, then navigate your browser to [http://localhost:8000/index.html](http://localhost:8000/index.html). The first startup may take a moment.

```bash
$ git clone https://github.com/ohanhi/elm-context-pattern.git
$ cd elm-context-pattern
$ elm-reactor
```


## File structure

```bash
.
├── api                     # "Mock backend", serves localization files
│   ├── en.json
│   ├── fi-formal.json
│   └── fi.json
├── elm-package.json        # Definition of the project dependencies
├── index.html              # The web page that initializes our app
├── README.md               # This documentation
└── src
    ├── Decoders.elm            # All JSON decoders
    ├── I18n.elm                # Helpers for localized strings
    ├── Main.elm                # Main handles the Context and AppState
    ├── Pages
    │   ├── Home.elm                # A Page that uses the Context
    │   └── Settings.elm            # A Page that can change the Context
    ├── Routing
    │   ├── Helpers.elm             # Definitions of routes and some helpers
    │   └── Router.elm              # The parent for Pages, includes the base layout
    ├── Styles.elm              # Some elm-css
    └── Types.elm               # All shared types
```


## How it works


### Initializing the application

The most important file to look at is [`Main.elm`](https://github.com/ohanhi/elm-context-pattern/blob/master/src/Main.elm). In this example app, the default set of translations is considered a prerequisite for starting the actual application. In your application, this might be the logged-in user's information, for example.

Our Model in Main is defined like so:

```elm
type alias Model =
    { appState : AppState
    , location : Location
    }

type AppState
    = NotReady Time
    | Ready Context Router.Model
```

We can see that the application can either be `NotReady` and have just a `Time` as payload, or it can be `Ready`, in which case it will have a complete Context as well as an initialized Router.

We are using [`programWithFlags`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#programWithFlags), which allows us to get the current time immediately from the [embedding code](https://github.com/ohanhi/elm-context-pattern/blob/e1554300258e0e715608ed0e5f557115065d3dd7/index.html#L16-L18). This could be used for initializing the app with some server-rendered JSON, as well.

This is how it works in the Elm side:

```elm
type alias Flags =
    { currentTime : Time
    }

init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    ( { appState = NotReady flags.currentTime
      , location = location
      }
    , WebData.Http.get "/api/en.json" HandleTranslationsResponse Decoders.decodeTranslations
    )
```

We are using [`ohanhi/elm-web-data`](http://package.elm-lang.org/packages/ohanhi/elm-web-data/latest) for the HTTP connections. With WebData, we represent any data that we retrieve from a server as a type like this:

```elm
type WebData a
    = NotAsked
    | Loading
    | Failure (Error String)
    | Success a
```

If you're unsure what the benefit of this is, you should read Kris Jenkins' blog post: [
How Elm Slays a UI Antipattern](http://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern.html).


Now, by far the most interesting of the other functions is `updateTranslations`, because translations are the prerequisite for initializing the main application.

Let's split it up a bit to explain what's going on.


```elm
case webData of
    Failure _ ->
        Debug.crash "OMG CANT EVEN DOWNLOAD."
```

In this example application, we simply keel over if the initial request fails. In a real application, this case must be handled with e.g. retrying or using a "best guess" default.


```elm
Success translations ->
```
Oh, jolly good, we got the translations we were looking for. Now all we need to do is either: a) initialize the whole thing, or b) update the current running application.

```elm
    case model.appState of
```
So if we don't have a ready app, let's create one now:

```elm
        NotReady time ->
            let
                initContext =
                    { currentTime = time
                    , translate = I18n.get translations
                    }

                ( initRouterModel, routerCmd ) =
                    Router.init initContext model.location
            in
                ( { model | appState = Ready initContext initRouterModel }
                , Cmd.map RouterMsg routerCmd
                )
```
Note that we use the `time` in the model to set the `initContext`'s value, and we set the `translate` function based on the translations we just received. This context is then passed to

If we do have an app ready, let's update the context while keeping the `routerModel` unchanged.

```elm
        Ready context routerModel ->
            ( { model | appState = Ready (updateContext context (UpdateTranslations translations)) routerModel }
            , Cmd.none
            )
```



Just to make it clear, here's the whole function:

```elm
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
                            Router.init initContext model.location
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
```

### Updating the Context

TODO
