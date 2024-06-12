module Page.Login exposing (..)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Html 
import Html.Events exposing (onClick)
import Element.Font exposing (Font)
import Element.Font as Font


type alias Model =
    { email : String
    , password : String
    , errorMessage : String
    }

init : Model
init =
    { email = ""
    , password = ""
    , errorMessage = "" }

-- UPDATE

type Msg
    = UpdateEmail String
    | UpdatePassword String
    | Submit

update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateEmail email ->
            { model | email = email }

        UpdatePassword password ->
            { model | password = password }

        Submit ->
            if model.email == "admin" && model.password == "password" then
                { model | errorMessage = "Login successful!" }
            else
                { model | errorMessage = "Invalid email or password." }

-- VIEW

view : Model -> Element Msg
view model =
    el
        [ width fill, height fill, Background.color (rgb 0.9 0.9 0.9) ]
        (column
            [ spacing 20, centerX, centerY ]
            [ el [ Border.rounded 5, Border.width 2, Border.color (rgb 0.2 0.2 0.7), padding 20, Background.color (rgb 0.95 0.95 1) ]
                (column
                    [ spacing 10 ]
                    [ text "Login"
                    , Input.email []
                        { onChange = UpdateEmail
                        , text = model.email
                        , placeholder  = Nothing
                        , label = Input.labelLeft [] (text "Email")
                        }

                    , Input.currentPassword []
                        { onChange = UpdatePassword
                        , text = model.password
                        , placeholder  = Nothing
                        , label = Input.labelLeft [] (text "Password")
                        , show = False
                        }

                    , Input.button [ Background.color (rgb 0.2 0.2 0.7), Element.focused [Background.color (rgb 0.1 0.1 0.5)]]
                            { onPress = Just Submit
                            , label = text "Login"
                            }
                    , text model.errorMessage
                    ]
                )
            ]
        )

