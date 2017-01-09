# 🌮 Taco 🌮


This repository serves as an example for building larger Single-Page Applications (SPAs) in Elm 0.18. The main focus is what we call the _Taco_ model. Taco can be used to provide some application-wide information to all the modules that need it. In this example we have the current time, as well as translations (I18n) in the taco. In a real application, you would likely have the current logged-in user in the taco.


## What's the big 🌮 idea?

Oftentimes in web applications there are some things that are singular and common by nature. The current time is an easy example of this. Of course we could have each module find out the current time on their own, but it does make sense to only handle that stuff in one place. Especially when the shared information is something like the translation files in our example app, it becomes apparent that retrieving the same file in every module would be a waste of time and resources.

How we've solved this in Elm is by introducing an extra parameter in the `view` functions:

```elm
view : Taco -> Model -> Html Msg
```

That's it, really.

The Taco is managed at the top-most module in the module hierarchy (`Main`), and its children, and their children, can politely ask for the Taco to be updated.

If need be, the Taco can just as well be given as a parameter to childrens' `init` and/or `update` functions. Most of the time it is not necessary, though, as is the case in this example application.


## How to try 🌮

There is a live demo here: [https://ohanhi.github.io/elm-taco/](https://ohanhi.github.io/elm-taco/)

To set up on your own computer, you will need `git` and `elm-reactor` 0.18 installed.

Simply clone the repository and start up elm-reactor, then navigate your browser to [http://localhost:8000/index.html](http://localhost:8000/index.html). The first startup may take a moment.

```bash
$ git clone https://github.com/ohanhi/elm-taco.git
$ cd elm-taco
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
    ├── Main.elm                # Main handles the Taco and AppState
    ├── Pages
    │   ├── Home.elm                # A Page that uses the Taco
    │   └── Settings.elm            # A Page that can change the Taco
    ├── Routing
    │   ├── Helpers.elm             # Definitions of routes and some helpers
    │   └── Router.elm              # The parent for Pages, includes the base layout
    ├── Styles.elm              # Some elm-css
    └── Types.elm               # All shared types
```


## How 🌮 works

### Initializing the application

The most important file to look at is [`Main.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Main.elm). In this example app, the default set of translations is considered a prerequisite for starting the actual application. In your application, this might be the logged-in user's information, for example.

Our Model in Main is defined like so:

```elm
type alias Model =
    { appState : AppState
    , location : Location
    }

type AppState
    = NotReady Time
    | Ready Taco Router.Model
```

We can see that the application can either be `NotReady` and have just a `Time` as payload, or it can be `Ready`, in which case it will have a complete Taco as well as an initialized Router.

We are using [`programWithFlags`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#programWithFlags), which allows us to get the current time immediately from the [embedding code](https://github.com/ohanhi/elm-taco/blob/36a9a12/index.html#L16-L18). This could be used for initializing the app with some server-rendered JSON, as well.

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
                    initTaco =
                        { currentTime = time
                        , translate = I18n.get translations
                        }

                    ( initRouterModel, routerCmd ) =
                        Router.init model.location
                in
                    ( { model | appState = Ready initTaco initRouterModel }
                    , Cmd.map RouterMsg routerCmd
                    )
```
Note that we use the `time` in the model to set the `initTaco`'s value, and we set the `translate` function based on the translations we just received. This taco is then set as a part of our `AppState`.

If we do have an app ready, let's update the taco while keeping the `routerModel` unchanged.

```elm
            Ready taco routerModel ->
                ( { model | appState = Ready (updateTaco taco (UpdateTranslations translations)) routerModel }
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
                        initTaco =
                            { currentTime = time
                            , translate = I18n.get translations
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
```

### Updating the Taco

We now know that the Taco is one half of what makes our application `Ready`, but how can we update the taco from some other place than the Main module? In [`Types.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Types.elm) we have the definition for `TacoUpdate`:

```elm
type TacoUpdate
    = NoUpdate
    | UpdateTime Time
    | UpdateTranslations Translations
```

And in [`Pages/Settings.elm`](https://github.com/ohanhi/elm-taco/blob/master/src/Pages/Settings.elm) we have the `update` function return one of them along with the typical `Model` and `Cmd Msg`:

```elm
update : Msg -> Model -> ( Model, Cmd Msg, TacoUpdate )
```

This obviously needs to be passed on also in the parent (`Router.elm`), which has the same signature for the update function. Then finally, back at the top level of our hierarchy, in the Main module we handle these requests to change the Taco for all modules.

```elm
updateRouter : Model -> Router.Msg -> ( Model, Cmd Msg )
updateRouter model routerMsg =
    case model.appState of
        Ready taco routerModel ->
            let
                ( nextRouterModel, routerCmd, ctxUpdate ) =
                    Router.update routerMsg routerModel

                nextTaco =
                    updateTaco taco ctxUpdate
            in
                ( { model | appState = Ready nextTaco nextRouterModel }
                , Cmd.map RouterMsg routerCmd
                )

-- ...

updateTaco : Taco -> TacoUpdate -> Taco
updateTaco taco ctxUpdate =
    case ctxUpdate of
        UpdateTime time ->
            { taco | currentTime = time }

        UpdateTranslations translations ->
            { taco | translate = I18n.get translations }

        NoUpdate ->
            taco
```

And that's it! I know it may be a little overwhelming, but take your time reading through the code and it will make sense. I promise. And if it doesn't, please put up an Issue so we can fix it!



## Credits and license

&copy; 2017 Ossi Hanhinen and Matias Klemola

Licensed under [BSD (3-clause)](LICENSE)
