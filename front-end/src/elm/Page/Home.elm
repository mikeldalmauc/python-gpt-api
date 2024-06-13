module Page.Home exposing (..)

import Element exposing (..)
import Element.Background as Background
import Data.Viewer as Viewer exposing (Viewer)
import Url exposing (Url)
import Time 
import Browser as B
import View.Layout as Layout
import View.HomeHeader as HomeHeader
import Html as H
import View.Navigation as Navigation

type alias Model =
    { 
    }

type alias InitOptions msg =
    { apiUrl : Url
    , viewer : Viewer
    , onChange : Msg -> msg
    }


init : InitOptions msg -> ( Model, Cmd msg )
init { apiUrl, viewer, onChange } =

    ( {  }
    , Cmd.none
    )



-- UPDATE
type alias UpdateOptions msg =
    { apiUrl : Url
    , viewer : Viewer
    , onChange : Msg -> msg
    }

type Msg
    = NoOp


update : UpdateOptions msg -> Msg -> Model -> ( Model, Cmd msg )
update options msg model =
    updateHelper options msg model
        |> Tuple.mapSecond (Cmd.map options.onChange)


updateHelper : UpdateOptions msg -> Msg -> Model -> ( Model, Cmd Msg )
updateHelper options msg model =
    case msg of
        NoOp -> (model, Cmd.none)

-- VIEW


type alias ViewOptions msg =
    { zone : Time.Zone
    , viewer : Viewer
    , onLogout : msg
    , onChange : Msg -> msg
    }


view : ViewOptions msg -> Model ->  B.Document msg
view { zone, viewer, onLogout, onChange } model =
    let
        ( role, hasPersonal ) =
            case viewer of
                Viewer.Guest ->
                    ( Navigation.guestHome
                    , False
                    )

                Viewer.User { username, imageUrl } ->
                    ( Navigation.userHome
                        { username = username
                        , imageUrl = imageUrl
                        , onLogout = onLogout
                        }
                    , True
                    )
    in
    
    { title = "Home"
    , body =
        [ Layout.view
            { name = "home"
            , role = role
            , maybeHeader = Just HomeHeader.view
            }
            [ H.div []
                [ H.text "Home"
                ]
            ]
        ]
    }