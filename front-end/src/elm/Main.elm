port module Main exposing (..)


import Html
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


type alias Model =

    { device : Device
    , dimensions : Dimensions
    , wheelModel : WheelModel
    , gesture : Swipe.Gesture
    , prevKeyboardEvent : Maybe KeyboardEvent
    , userModel : UserModel
    }

type alias WheelModel =
    { deltaX : Float
    , deltaY : Float
    }

type alias Dimensions =
    { width : Int
    , height : Int
    }

type UserModel
    = LoadingUser LoadingUserModel
    | Success SuccessModel
    | Failure Error
    
type alias LoadingUserModel =
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , zone : Time.Zone
    }

type alias SuccessModel =
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , zone : Time.Zone
    , viewer : Viewer
    , page : Page
    , reloadPage : Bool
    }

type Error
    = BadConfig

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
                        initLoadingUser model 
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , token = token
                            }

                    Ok Nothing ->
                        initSuccess model
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , maybeZone = Nothing
                            , viewer = Viewer.Guest
                            }
                        

                    Err (Config.BadToken error) ->
                        initSuccess model
                            { apiUrl = apiUrl
                            , url = url
                            , key = key
                            , maybeZone = Nothing
                            , viewer = Viewer.Guest
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
                { device = Element.classifyDevice {width=600, height=1200}
                , dimensions = {width=600, height=1200}
                , wheelModel = initWheelModel
                , gesture = Swipe.blanco
                , prevKeyboardEvent = Nothing
                , userModel = Failure BadConfig
                }
            , Port.Outgoing.logError ("Configuration error: " ++ JD.errorToString error)
            )

initLoadingUser : Model ->  
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , token : Token
    }
    -> ( Model, Cmd Msg )
initLoadingUser model { apiUrl, url, key, token } =
    ( { model | userModel = 
                                LoadingUser
                                    { apiUrl = apiUrl
                                    , url = url
                                    , key = key
                                    , zone = Time.utc
                                    }
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
    Model -> 
    { apiUrl : Url
    , url : Url
    , key : BN.Key
    , maybeZone : Maybe Time.Zone
    , viewer : Viewer
    }
    -> ( Model, Cmd Msg )
initSuccess model { apiUrl, url, key, maybeZone, viewer } =
    let
        ( zone, zoneCmd ) =
            case maybeZone of
                Nothing ->
                    ( Time.utc, getZone )

                Just givenZone ->
                    ( givenZone, Cmd.none )

        ( page, pageCmd ) =
            getPageFromUrl apiUrl key viewer Nothing url
    in
    ( {model | userModel = 
        Success
        { apiUrl = apiUrl
        , url = url
        , key = key
        , zone = zone
        , viewer = viewer
        , page = page
        , reloadPage = True
        , maybeArticle = Nothing
        }
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
      Wheel WheelModel
    | Swipe Swipe.Event
    | SwipeEnd Swipe.Event
    | DeviceClassified Dimensions
    | HandleKeyboardEvent KeyboardEvent
    | GotZone Time.Zone
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
        HandleKeyboardEvent event ->
            let
                modelK = { model |  prevKeyboardEvent = Just event }
            in
                case event.keyCode of
                    Key.Right ->  
                        ( modelK, Cmd.none )
                    Key.Left ->  
                        ( modelK, Cmd.none )

                    Key.Up -> 
                        ( modelK, Cmd.none )
                    Key.Down ->  
                        ( modelK, Cmd.none )
                    _ -> 
                        (modelK, Cmd.none)

        Wheel wheelModel ->
            if  wheelModel.deltaY < 0.0 then                       
                ( { model |  wheelModel = initWheelModel }, Cmd.none )
            else 
                ( { model |  wheelModel = wheelModel }, Cmd.none )

        Swipe touch ->
            ({ model | gesture = Swipe.record touch model.gesture }, Cmd.none)
                    
        SwipeEnd touch ->
            let
                gesture = Swipe.record touch model.gesture
            in
                if (Swipe.isUpSwipe 100.0 gesture) then
                    ({ model | gesture = Swipe.blanco}, Cmd.none)
                else if (Swipe.isDownSwipe 100.0 gesture) then
                    ({ model | gesture = Swipe.blanco}, Cmd.none)
                else
                    ({ model | gesture = Swipe.blanco}, Cmd.none)

        DeviceClassified flags ->
            ( { model | device = (Element.classifyDevice flags), dimensions = flags } , Cmd.none)

        NoOp ->
            ( model, Cmd.none )
            

view : Model -> Html.Html Msg
view model =
    let 
        (deviceClass, deviceOrientation) = 
            case model.device of
                { class, orientation} -> (class, orientation)
    in
        case deviceClass of
            Phone ->
                Html.div 
                    [ Swipe.onStart Swipe
                    , Swipe.onMove Swipe
                    , Swipe.onEndWithOptions 
                        { stopPropagation = True
                        , preventDefault = False
                        } 
                        SwipeEnd
                    ]
                    [phoneLayout model]

            Tablet ->
                Html.div 
                    [ Swipe.onStart Swipe
                    , Swipe.onMove Swipe
                    , Swipe.onEndWithOptions 
                        { stopPropagation = True
                        , preventDefault = False
                        } 
                        SwipeEnd
                    ]
                    [phoneLayout model]
            Desktop ->
                desktopLayout model
            BigDesktop ->
                desktopLayout model

phoneLayout : Model -> Html.Html Msg
phoneLayout model = 
    let 
        (deviceClass, deviceOrientation) = 
            case model.device of
                { class, orientation} -> (class, orientation)

    in 
        case deviceOrientation of
                Portrait ->
                    layout [ width fill, height fill
                    , behindContent <| infoDebug model] <| infoDebug model

                Landscape ->
                    layout [ width fill, height fill
                    , behindContent <| infoDebug model] <| infoDebug model

                        


desktopLayout : Model -> Html.Html Msg
desktopLayout model = 
    layout
        [ width fill, height fill
        , behindContent <| infoDebug model] 
        <| infoDebug model
        

infoDebug : Model -> Element msg
infoDebug model =
    column 
        [ width fill, height fill, Font.size 11, padding 10
        , Font.color <| rgb 0 0 0
        , Background.color <| rgb 255 255 255 
        , alignBottom, alignRight]
        [ text <| "wheel Delta Y: " ++ fromFloat model.wheelModel.deltaY
        , text <| "wheel Delta X: " ++ fromFloat model.wheelModel.deltaX
        , text <| "device: " ++ Debug.toString model.device
        , text <| "dimensions: " ++ Debug.toString model.dimensions
        , text <| "gesture: " ++ Debug.toString model.gesture
        ]


animatedText : String -> List String ->  Html.Html msg 
animatedText class words = 
    let 
         animationAttrs = 
            "transform: scale(0.94);"
            ++"animation: scale 3s forwards cubic-bezier(0.5, 1, 0.89, 1);"
            ++ "white-space:pre"
    in
        Html.div [Attrs.class class, Attrs.attribute "style" animationAttrs]
            <| List.map (\word ->  Html.span [] [Html.text word]) words

-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--

port onWheel : (Value -> msg) -> Sub msg

wheelDecoder : Decoder WheelModel
wheelDecoder =
    Decode.map2 WheelModel
        (Decode.field "deltaX" Decode.float)
        (Decode.field "deltaY" Decode.float)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyDown (Decode.map HandleKeyboardEvent decodeKeyboardEvent)
        , onWheel
            (\val ->
                case Decode.decodeValue wheelDecoder val of
                    Ok wheelModel ->
                        Wheel wheelModel

                    Err _ ->
                        NoOp
            )
        , onResize 
            (\width height ->
                DeviceClassified { width = width, height = height })
        ]