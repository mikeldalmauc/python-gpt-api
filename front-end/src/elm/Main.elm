port module Main exposing (..)


import Html as H
import Html.Attributes as Attrs

import Element exposing (..)
import Element.Font as Font
import Element.Background as Background

import Browser as B
import Browser.Events exposing (onResize)
import Browser.Navigation as BN
import Browser.Events exposing (onKeyDown)

import Swipe
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)
import Keyboard.Key as Key

import String exposing (fromFloat, fromInt)
import Json.Decode as JD
import Time
import Url exposing (Url)
import Task
import Port.Outgoing

import Data.Route as Route exposing (Route)
import Page.Home as HomePage
import Page.Login as LoginPage
import Page.NotAuthorized as NotAuthorizedPage
import Page.NotFound as NotFoundPage
import Page.Error as ErrorPage

import Api
import Api.GetUser as GetUser

import Data.Token exposing (Token)
import Data.User exposing (User)
import Data.Username exposing (Username)
import Data.Viewer as Viewer exposing (Viewer)
import Data.Config as Config


main : Program Flags Model Msg
main =
    B.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }


-- FLAGS


type alias Flags =
    JD.Value



-- MODEL



type Model
    = LoadingUser LoadingUserModel
    | Success SuccessModel
    | Failure Error

type alias LoadingUserModel =
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , zone : Time.Zone
    , device : Device
    , dimensions : Dimensions
    , wheelModel : WheelModel
    , gesture : Swipe.Gesture
    , prevKeyboardEvent : Maybe KeyboardEvent
    }

type alias SuccessModel =
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , zone : Time.Zone
    , viewer : Viewer
    , page : Page
    , reloadPage : Bool
    , device : Device
    , dimensions : Dimensions
    , wheelModel : WheelModel
    , gesture : Swipe.Gesture
    , prevKeyboardEvent : Maybe KeyboardEvent
    }

type Error
    = BadConfig
type alias WheelModel =
    { deltaX : Float
    , deltaY : Float
    }

type alias Dimensions =
    { width : Int
    , height : Int
    }
    

type Page
    = Login LoginPage.Model
    | Home HomePage.Model
    | NotAuthorized
    | NotFound


init : Flags -> Url -> BN.Key -> ( Model, Cmd Msg )
init flags url key =
    case JD.decodeValue Config.decoder flags of
        Ok {  width
            , height
            , apiUrl
            , resultMaybeToken } ->
            let
                model =   
                    { device = Element.classifyDevice {width=width, height=height}
                    , dimensions = {width=width, height=height}
                    , wheelModel = initWheelModel
                    , gesture = Swipe.blanco
                    , prevKeyboardEvent = Nothing
                    , userModel =  Failure BadConfig
                    }
            in
                case resultMaybeToken of
                    Ok (Just token) ->
                        initLoadingUser 
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , token = token
                            , device = Element.classifyDevice {width=width, height=height}
                            , dimensions = {width=width, height=height}
                            , wheelModel = initWheelModel
                            , gesture = Swipe.blanco
                            , prevKeyboardEvent = Nothing
                            }

                    Ok Nothing ->
                        initSuccess
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , maybeZone = Nothing
                            , viewer = Viewer.Guest
                            , device = Element.classifyDevice {width=width, height=height}
                            , dimensions = {width=width, height=height}
                            , wheelModel = initWheelModel
                            , gesture = Swipe.blanco
                            , prevKeyboardEvent = Nothing
                            }
                        

                    Err (Config.BadToken error) ->
                        initSuccess
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , maybeZone = Nothing
                            , viewer = Viewer.Guest
                            , device = Element.classifyDevice {width=width, height=height}
                            , dimensions = {width=width, height=height}
                            , wheelModel = initWheelModel
                            , gesture = Swipe.blanco
                            , prevKeyboardEvent = Nothing
                            }
                            |> Tuple.mapSecond
                                (\cmd ->
                                    Cmd.batch
                                        [ Port.Outgoing.logError ("Bad token: " ++ JD.errorToString error)
                                        , cmd
                                        ]
                                )
        Err error ->
            (
              Failure BadConfig
            , Port.Outgoing.logError ("Configuration error: " ++ JD.errorToString error)
            )

initLoadingUser :  
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , token : Token
    , device : Device
    , dimensions : Dimensions
    , wheelModel : WheelModel
    , gesture : Swipe.Gesture
    , prevKeyboardEvent : Maybe KeyboardEvent
    }
    -> ( Model, Cmd Msg )
initLoadingUser { apiUrl, url, key, token, device, dimensions, wheelModel, gesture, prevKeyboardEvent } =
    ( LoadingUser
        { apiUrl = apiUrl
        , url = url
        , key = key
        , zone = Time.utc
        , device = device
        , dimensions = dimensions
        , wheelModel = wheelModel
        , gesture = gesture
        , prevKeyboardEvent = prevKeyboardEvent
        }
                            
    , Cmd.batch
        [ getZone
        , GetUser.getUser
            apiUrl
            { token = token
            , onResponse = GotUserResponse
            }
        ]
    )

initSuccess :
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , maybeZone : Maybe Time.Zone
    , viewer : Viewer
    , device : Device
    , dimensions : Dimensions
    , wheelModel : WheelModel
    , gesture : Swipe.Gesture
    , prevKeyboardEvent : Maybe KeyboardEvent
    }
    -> ( Model, Cmd Msg )
initSuccess { apiUrl, url, key, maybeZone, viewer, device, dimensions, wheelModel, gesture, prevKeyboardEvent  } =
    let
        ( zone, zoneCmd ) =
            case maybeZone of
                Nothing ->
                    ( Time.utc, getZone )

                Just givenZone ->
                    ( givenZone, Cmd.none )

        ( page, pageCmd ) =
            getPageFromUrl apiUrl key viewer url
    in
    ( Success
        { apiUrl = apiUrl
        , url = url
        , key = key
        , zone = zone
        , viewer = viewer
        , page = page
        , reloadPage = True
        , device = device
        , dimensions = dimensions
        , wheelModel = wheelModel
        , gesture = gesture
        , prevKeyboardEvent = prevKeyboardEvent
        }
    , Cmd.batch
        [ zoneCmd
        , pageCmd
        ]
    )

initWheelModel : WheelModel
initWheelModel = 
    { deltaX = 0, deltaY = 0 }
    


getZone : Cmd Msg
getZone =
    Task.perform GotZone Time.here


getPageFromUrl : Url -> BN.Key -> Viewer -> Url -> ( Page, Cmd Msg )
getPageFromUrl apiUrl key viewer url =
    case Route.fromUrl url of
        Just route ->
            getPageFromRoute apiUrl key viewer route

        Nothing ->
            ( NotFound, Cmd.none )

getPageFromRoute : Url -> BN.Key -> Viewer -> Route -> ( Page, Cmd Msg )
getPageFromRoute apiUrl key viewer route =
    case route of
        Route.Home ->
            HomePage.init
                { apiUrl = apiUrl
                , viewer = viewer
                , onChange = ChangedPage << ChangedHomePage
                }
                |> Tuple.mapFirst Home

        Route.Login ->
            withGuestForPage
                (always
                    (LoginPage.init
                        { onChange = ChangedPage << ChangedLoginPage }
                        |> Tuple.mapFirst Login
                    )
                )
                key
                viewer


-- UPDATE

type Msg =
    --   Wheel WheelModel
    -- | Swipe Swipe.Event
    -- | SwipeEnd Swipe.Event
    -- | DeviceClassified Dimensions
    -- | HandleKeyboardEvent KeyboardEvent

    GotZone Time.Zone
    | ClickedLink B.UrlRequest
    | ChangedUrl Url
    | ChangedRoute Route
    | ChangedPage PageMsg
    | GotUserResponse (Result (Api.Error ()) User)

    | LoggedIn User
    | LoggedOut
    | NoOp
    

type PageMsg
    = ChangedHomePage HomePage.Msg
    | ChangedLoginPage LoginPage.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                B.Internal url ->
                    pushUrl url model

                B.External url ->
                    loadUrl url model

        ChangedUrl url ->
            changeUrl url model

        GotZone zone ->
            setZone zone model

        GotUserResponse result ->
            handleUserResponse result model

        LoggedIn user ->
            loginUser user model

        LoggedOut ->
            logout model

        ChangedRoute route ->
            changeRoute route model

        ChangedPage pageMsg ->
            updatePage pageMsg model

        -- HandleKeyboardEvent event ->
        --     let
        --         modelK = { model |  prevKeyboardEvent = Just event }
        --     in
        --         case event.keyCode of
        --             Key.Right ->  
        --                 ( modelK, Cmd.none )
        --             Key.Left ->  
        --                 ( modelK, Cmd.none )

        --             Key.Up -> 
        --                 ( modelK, Cmd.none )
        --             Key.Down ->  
        --                 ( modelK, Cmd.none )
        --             _ -> 
        --                 (modelK, Cmd.none)

        -- Wheel wheelModel ->
        --     if  wheelModel.deltaY < 0.0 then                       
        --         ( { model |  wheelModel = initWheelModel }, Cmd.none )
        --     else 
        --         ( { model |  wheelModel = wheelModel }, Cmd.none )

        -- Swipe touch ->
        --     ({ model | gesture = Swipe.record touch model.gesture }, Cmd.none)
                    
        -- SwipeEnd touch ->
        --     let
        --         gesture = Swipe.record touch model.gesture
        --     in
        --         if (Swipe.isUpSwipe 100.0 gesture) then
        --             ({ model | gesture = Swipe.blanco}, Cmd.none)
        --         else if (Swipe.isDownSwipe 100.0 gesture) then
        --             ({ model | gesture = Swipe.blanco}, Cmd.none)
        --         else
        --             ({ model | gesture = Swipe.blanco}, Cmd.none)

        -- DeviceClassified flags ->
        --     ( { model | device = (Element.classifyDevice flags), dimensions = flags } , Cmd.none)

        NoOp ->
            ( model, Cmd.none )


pushUrl : Url -> Model -> ( Model, Cmd msg )
pushUrl url =
    withSuccessModel
        (\subModel ->
            ( subModel
            , BN.pushUrl subModel.key (Url.toString url)
            )
        )


loadUrl : String -> Model -> ( Model, Cmd msg )
loadUrl url model =
    ( model
    , BN.load url
    )


changeUrl : Url -> Model -> ( Model, Cmd Msg )
changeUrl url =
    withSuccessModel
        (\subModel ->
            if subModel.reloadPage then
                let
                    ( page, cmd ) =
                        getPageFromUrl subModel.apiUrl subModel.key subModel.viewer url
                in
                ( { subModel | url = url, page = page }
                , cmd
                )

            else
                ( { subModel | url = url, reloadPage = True }
                , Cmd.none
                )
        ) 


setZone : Time.Zone -> Model -> ( Model, Cmd msg )
setZone zone model =
    ( withModel
        { onLoadingUser = \subModel -> LoadingUser { subModel | zone = zone }
        , onSuccess = \subModel -> Success { subModel | zone = zone }
        , onFailure = always model
        }
        model
    , Cmd.none
    )

handleUserResponse : Result (Api.Error ()) User -> Model -> ( Model, Cmd Msg )
handleUserResponse result =
    withLoadingUserModel
        (\{ apiUrl, url, key, zone, device, dimensions, wheelModel, gesture, prevKeyboardEvent} ->
            case result of
                Ok user ->
                    initSuccess
                        { apiUrl = apiUrl
                        , url = url
                        , key = key
                        , maybeZone = Just zone
                        , viewer = Viewer.User user
                        , device = device
                        , dimensions = dimensions
                        , wheelModel = wheelModel
                        , gesture = gesture
                        , prevKeyboardEvent = prevKeyboardEvent
                        }

                Err error ->
                    initSuccess
                        { apiUrl = apiUrl
                        , url = url
                        , key = key
                        , maybeZone = Just zone
                        , viewer = Viewer.Guest
                        , device = device
                        , dimensions = dimensions
                        , wheelModel = wheelModel
                        , gesture = gesture
                        , prevKeyboardEvent = prevKeyboardEvent
                        }
                        |> Tuple.mapSecond
                            (\cmd ->
                                Cmd.batch
                                    [ Port.Outgoing.logError ("Unable to get user: " ++ Api.errorToString error)
                                    , cmd
                                    ]
                            )
        )


loginUser : User -> Model -> ( Model, Cmd Msg )
loginUser user =
    withSuccessModel
        (\subModel ->
            ( { subModel | viewer = Viewer.User user }
            , Cmd.batch
                [ Port.Outgoing.saveToken user.token
                , Route.redirectToHome subModel.key
                ]
            )
        )


logout : Model -> ( Model, Cmd Msg )
logout =
    withSuccessModel
        (\subModel ->
            ( { subModel | viewer = Viewer.Guest }
            , Cmd.batch
                [ Port.Outgoing.deleteToken
                , Route.redirectToHome subModel.key
                ]
            )
        )

changeRoute : Route -> Model -> ( Model, Cmd Msg )
changeRoute route =
    withSuccessModel
        (\subModel ->
            ( { subModel | reloadPage = False }
            , Route.pushUrl subModel.key route
            )
        )

updatePage : PageMsg -> Model -> ( Model, Cmd Msg )
updatePage msg =
    withSuccessModel
        (\subModel ->
            case msg of
                ChangedHomePage pageMsg ->
                    updateHomePage pageMsg subModel

                ChangedLoginPage pageMsg ->
                    updateLoginPage pageMsg subModel
        )


updateHomePage : HomePage.Msg -> SuccessModel -> ( SuccessModel, Cmd Msg )
updateHomePage pageMsg subModel =
    case subModel.page of
        Home pageModel ->
            HomePage.update
                { apiUrl = subModel.apiUrl
                , viewer = subModel.viewer
                , onChange = ChangedPage << ChangedHomePage
                }
                pageMsg
                pageModel
                |> Tuple.mapFirst
                    (\newPageModel ->
                        { subModel | page = Home newPageModel }
                    )

        _ ->
            ( subModel, Cmd.none )


updateLoginPage : LoginPage.Msg -> SuccessModel -> ( SuccessModel, Cmd Msg )
updateLoginPage pageMsg subModel =
    case subModel.page of
        Login pageModel ->
            LoginPage.update
                { apiUrl = subModel.apiUrl
                , onLoggedIn = LoggedIn
                , onChange = ChangedPage << ChangedLoginPage
                }
                pageMsg
                pageModel
                |> Tuple.mapFirst
                    (\newPageModel ->
                        { subModel | page = Login newPageModel }
                    )

        _ ->
            ( subModel, Cmd.none )


-- VIEW


view : Model -> B.Document Msg
view model =
    let
        { title, body } =
            withModel
                { onLoadingUser = viewLoadingUserPage
                , onSuccess = viewSuccessPage
                , onFailure = viewFailurePage
                }
                model
    in
    { title =
        if String.isEmpty title then
            "Conduit"

        else
            title ++ " - Conduit"
    , body = body ++ [infoDebug model]
    }


viewLoadingUserPage : LoadingUserModel -> B.Document msg
viewLoadingUserPage _ =
    { title = ""
    , body =
        [ H.text ""
        ]
    }


viewSuccessPage : SuccessModel -> B.Document Msg
viewSuccessPage { zone, viewer, page } =
    case page of
        Home pageModel ->
            HomePage.view
                { zone = zone
                , viewer = viewer
                , onLogout = LoggedOut
                , onChange = ChangedPage << ChangedHomePage
                }
                pageModel

        Login pageModel ->
            LoginPage.view
                { onChange = ChangedPage << ChangedLoginPage
                }
                pageModel

        NotAuthorized ->
            NotAuthorizedPage.view

        NotFound ->
            NotFoundPage.view
                { viewer = viewer
                , onLogout = LoggedOut
                }


viewFailurePage : Error -> B.Document msg
viewFailurePage badConfig =
    ErrorPage.view
        { title = "Configuration Error"
        , message = "Please check your configuration. You can view the logs to diagnose and fix the specific problem."
        }


-- view : Model -> Html.Html Msg
-- view model =
--     let 
--         (deviceClass, deviceOrientation) = 
--             case model.device of
--                 { class, orientation} -> (class, orientation)
--     in
--         case deviceClass of
--             Phone ->
--                 Html.div 
--                     [ Swipe.onStart Swipe
--                     , Swipe.onMove Swipe
--                     , Swipe.onEndWithOptions 
--                         { stopPropagation = True
--                         , preventDefault = False
--                         } 
--                         SwipeEnd
--                     ]
--                     [phoneLayout model]

--             Tablet ->
--                 Html.div 
--                     [ Swipe.onStart Swipe
--                     , Swipe.onMove Swipe
--                     , Swipe.onEndWithOptions 
--                         { stopPropagation = True
--                         , preventDefault = False
--                         } 
--                         SwipeEnd
--                     ]
--                     [phoneLayout model]
--             Desktop ->
--                 desktopLayout model
--             BigDesktop ->
--                 desktopLayout model


-- phoneLayout : Model -> Html.Html Msg
-- phoneLayout model = 
--     let 
--         (deviceClass, deviceOrientation) = 
--             case model.device of
--                 { class, orientation} -> (class, orientation)

--     in 
--         case deviceOrientation of
--                 Portrait ->
--                     layout [ width fill, height fill
--                     , behindContent <| infoDebug model] <| infoDebug model

--                 Landscape ->
--                     layout [ width fill, height fill
--                     , behindContent <| infoDebug model] <| infoDebug model

                        


-- desktopLayout : Model -> Html.Html Msg
-- desktopLayout model = 
--     layout
--         [ width fill, height fill
--         , behindContent <| infoDebug model] 
--         <| infoDebug model


-- HELPERS

withLoadingUserModel : (LoadingUserModel -> ( Model, Cmd msg )) -> Model -> ( Model, Cmd msg )
withLoadingUserModel onLoadingUser model =
    let
        default =
            ( model, Cmd.none )
    in
    withModel
        { onLoadingUser = onLoadingUser
        , onSuccess = always default
        , onFailure = always default
        }
        model


withSuccessModel : (SuccessModel -> ( SuccessModel, Cmd msg )) -> Model -> ( Model, Cmd msg )
withSuccessModel onSuccess model =
    let
        default =
            ( model, Cmd.none )
    in
    withModel
        { onLoadingUser = always default
        , onSuccess = Tuple.mapFirst Success << onSuccess
        , onFailure = always default
        }
        model


withModel :
    { onLoadingUser : LoadingUserModel -> a
    , onSuccess : SuccessModel -> a
    , onFailure : Error -> a
    }
    -> Model
    -> a
withModel { onLoadingUser, onSuccess, onFailure } model =
    case model of
        LoadingUser subModel ->
            onLoadingUser subModel

        Success subModel ->
            onSuccess subModel

        Failure error ->
            onFailure error


infoDebug : Model -> H.Html msg
infoDebug model =
    let 
        viewDebugData = \debugData -> 
            layout [] <|
                column 
                [ width fill, height fill, Font.size 11, padding 10
                , Font.color <| rgb 0 0 0
                , Background.color <| rgb 255 255 255 
                , alignBottom, alignRight]
                [ text <| "wheel Delta Y: " ++ fromFloat debugData.wheelModel.deltaY
                , text <| "wheel Delta X: " ++ fromFloat debugData.wheelModel.deltaX
                , text <| "device: " ++ Debug.toString debugData.device
                , text <| "dimensions: " ++ Debug.toString debugData.dimensions
                , text <| "gesture: " ++ Debug.toString debugData.gesture
                , text <| "apiURL: " ++ Debug.toString debugData.apiURL
                ]
    in
        case model of
            LoadingUser loadingUserModel ->
                viewDebugData 
                    { wheelModel = loadingUserModel.wheelModel
                    , device = loadingUserModel.device  
                    , dimensions = loadingUserModel.dimensions
                    , gesture = loadingUserModel.gesture
                    , apiURL = loadingUserModel.apiUrl
                    }
            Success successModel ->
                viewDebugData
                    { wheelModel = successModel.wheelModel
                    , device = successModel.device  
                    , dimensions = successModel.dimensions
                    , gesture = successModel.gesture
                    , apiURL = successModel.apiUrl
                    }
            Failure error ->  
                layout [] <|
                    column 
                    [ width fill, height fill, Font.size 11, padding 10
                    , Font.color <| rgb 0 0 0
                    , Background.color <| rgb 255 255 255 
                    , alignBottom, alignRight]
                    [ text <| "Error: " ++ Debug.toString error
                    ]

      


withGuestForPage : (() -> ( Page, Cmd Msg )) -> BN.Key -> Viewer -> ( Page, Cmd Msg )
withGuestForPage toPage key viewer =
    case viewer of
        Viewer.Guest ->
            toPage ()

        Viewer.User _ ->
            ( NotFound, Route.redirectToHome key )


withUserForPage : (User -> ( Page, Cmd Msg )) -> Viewer -> ( Page, Cmd Msg )
withUserForPage toPage viewer =
    case viewer of
        Viewer.Guest ->
            ( NotAuthorized, Cmd.none )

        Viewer.User user ->
            toPage user

port onWheel : (JD.Value -> msg) -> Sub msg

wheelDecoder : JD.Decoder WheelModel
wheelDecoder =
    JD.map2 WheelModel
        (JD.field "deltaX" JD.float)
        (JD.field "deltaY" JD.float)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [
        -- onKeyDown (JD.map HandleKeyboardEvent decodeKeyboardEvent)
        -- , onWheel
        --     (\val ->
        --         case JD.decodeValue wheelDecoder val of
        --             Ok wheelModel ->
        --                 Wheel wheelModel

        --             Err _ ->
        --                 NoOp
        --     )
        -- , onResize 
        --     (\width height ->
        --         DeviceClassified { width = width, height = height })
        ]