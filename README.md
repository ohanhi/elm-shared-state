# Elm Shared State example

This repository serves as an example for organizing large Single-Page Applications (SPAs) in Elm 0.19. It was previously called elm-taco and was renamed to be less witty and more to the point.

This repository assumes understanding of the Elm Architecture and the way you can structure independent concepts into sub-modules in Elm. **This is not a good example to base a small hobby projects on! It is also not an illustrative example for people who are just coming to Elm!**

The main focus of this repository is the _SharedState_ model. SharedState can be used to provide some application-wide information to all the modules that need it. In this example we have the current time, as well as translations (I18n) in the shared state. In an application with login, you would store the login data in the SharedState. Richard Feldman's [elm-spa-example](https://github.com/rtfeldman/elm-spa-example) uses a similar technique, though he calls it a Session.


## What's the big idea?

Oftentimes in web applications there are some things that are singular and common by nature. The current time is an easy example of this. Of course we could have each module find out the current time on their own, but it does make sense to only handle that stuff in one place. Especially when the shared information is something like the translation files in our example app, it becomes apparent that retrieving the same file in every module would be a waste of time and resources.

How we've solved this in Elm is by introducing an extra parameter in the relevant `view`, `update`, etc. functions:

```elm
view : SharedState -> Model -> Html Msg
```

That's it, really.

The SharedState is managed at the top-most module in the module hierarchy (`Main`), and its children, and their children, can politely ask for the SharedState to be updated.

If need be, the SharedState can just as well be given as a parameter to childrens' `init` and/or `update` functions.


## How to try SharedState

There is a live demo here: [https://ohanhi.github.io/elm-shared-state/](https://ohanhi.github.io/elm-shared-state/)

To set up on your own computer, you will need `git` and `elm` 0.19 installed.

Simply clone the repository, build the Elm app and serve it in your favorite manner. For example:

```bash
$ git clone https://github.com/ohanhi/elm-shared-state.git
$ cd elm-shared-state
$ elm make src/Main.elm --output=elm.js
$ python -m SimpleHTTPServer 8000
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
    ├── Main.elm                # Main handles the SharedState and AppState
    ├── Pages
    │   ├── Home.elm                # A Page that uses the SharedState
    │   └── Settings.elm            # A Page that can change the SharedState
    ├── Routing
    │   ├── Helpers.elm             # Definitions of routes and some helpers
    │   └── Router.elm              # The parent for Pages, includes the base layout
    ├── Styles.elm              # Some elm-css
    └── Types.elm               # All shared types
```


## How :sharedState: works

### Initializing the application

The most important file to look at is [`Main.elm`](https://github.com/ohanhi/elm-shared-state/blob/master/src/Main.elm). In this example app, the default set of translations is considered a prerequisite for starting the actual application. In your application, this might be the logged-in user's information, for example.

Our Model in Main is defined like so:

```elm
type alias Model =
    { appState : AppState
    , navKey : Browser.Navigation.Key
    , url : Url
    }

type AppState
    = NotReady Posix
    | Ready SharedState Router.Model
```

We can see that the application can either be `NotReady` and have just a `Posix` (time) as payload, or it can be `Ready`, in which case it will have a complete SharedState as well as an initialized Router.

We are using [`Browser.application`](https://package.elm-lang.org/packages/elm/browser/latest/Browser#application), which allows us to get the current time immediately through flags from the [embedding code](https://github.com/ohanhi/elm-shared-state/blob/66bde28/index.html#L18-L23). This could be used for initializing the app with some server-rendered JSON, as well.

This is how it works in the Elm side:

```elm
type alias Flags =
    { currentTime : Int
    }


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { appState = NotReady (Time.millisToPosix flags.currentTime)
      , url = url
      , navKey = navKey
      }
    , Http.get "/api/en.json" HandleTranslationsResponse Decoders.decodeTranslations
    )
```

We are using RemoteData for the HTTP connections. With RemoteData, we represent any data that we retrieve from a server as a type like this:

```elm
type RemoteData e a
    = NotAsked
    | Loading
    | Failure e
    | Success a
```

If you're unsure what the benefit of this is, you should read Kris Jenkins' blog post: [
How Elm Slays a UI Antipattern](http://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern.html).


Now, by far the most interesting of the other functions is `updateTranslations`, because translations are the prerequisite for initializing the main application.

Let's split it up a bit to explain what's going on.


```elm
case webData of
    Failure _ ->
        Debug.todo "OMG CANT EVEN DOWNLOAD."
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
```
Note that we use the `time` in the model to set the `initSharedState`'s value, and we set the `translate` function based on the translations we just received. This sharedState is then set as a part of our `AppState`.

If we do have an app ready, let's update the sharedState while keeping the `routerModel` unchanged.

```elm
            Ready sharedState routerModel ->
                ( { model | appState = Ready (updateSharedState sharedState (UpdateTranslations translations)) routerModel }
                , Cmd.none
                )
```



### Updating the SharedState

We now know that the SharedState is one half of what makes our application `Ready`, but how can we update the sharedState from some other place than the Main module? In [`Types.elm`](https://github.com/ohanhi/elm-shared-state/blob/master/src/Types.elm) we have the definition for `SharedStateUpdate`:

```elm
type SharedStateUpdate
    = NoUpdate
    | UpdateTime Time
    | UpdateTranslations Translations
```

And in [`Pages/Settings.elm`](https://github.com/ohanhi/elm-shared-state/blob/master/src/Pages/Settings.elm) we have the `update` function return one of them along with the typical `Model` and `Cmd Msg`:

```elm
update : SharedState -> Msg -> Model -> ( Model, Cmd Msg, SharedStateUpdate )
```

This obviously needs to be passed on also in the parent (`Router.elm`), which has the same signature for the update function. Then finally, back at the top level of our hierarchy, in the Main module we handle these requests to change the SharedState for all modules.

```elm
updateSharedState : SharedState -> SharedStateUpdate -> SharedState
updateSharedState sharedState sharedStateUpdate =
    case sharedStateUpdate of
        UpdateTime time ->
            { sharedState | currentTime = time }

        UpdateTranslations translations ->
            { sharedState | translate = I18n.get translations }

        NoUpdate ->
            sharedState
```

And that's it! I know it may be a little overwhelming, but take your time reading through the code and it will make sense. I promise. And if it doesn't, please put up an Issue so we can fix it!



## Credits and license

&copy; 2017-2019 Ossi Hanhinen and Matias Klemola

Licensed under [BSD (3-clause)](LICENSE)
