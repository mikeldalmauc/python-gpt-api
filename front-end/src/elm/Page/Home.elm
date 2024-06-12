module Page.Home exposing (..)

import Element exposing (..)
import Element.Background as Background

type alias Model =
    { 
    }

init : Model
init =
    {   }

-- UPDATE

type Msg
    = NoOp

update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp -> (model)

-- VIEW

view : Model -> Element Msg
view model =
    el
    [ width fill, height fill, Background.color (rgb 0.9 0.9 0.9) ]
    (text "something ")