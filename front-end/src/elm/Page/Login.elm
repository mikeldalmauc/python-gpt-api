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
import Url exposing (Url)
import Data.User exposing (User)
import Api
import Api.Login as Login
import Lib.Validation as V
import Data.Validation as V
import Browser as B

import Data.Email exposing (Email)
import Data.Password exposing (Password)
import Lib.Task as Task

import View.Column as Column
import View.Layout as Layout
import View.Login as Login
import View.Navigation as Navigation
import Html as H


type alias Model =
    { email : String
    , password : String
    , errorMessages : List String
    , isDisabled : Bool
    }

type alias InitOptions msg =
    { onChange : Msg -> msg
    }

init : InitOptions msg -> ( Model, Cmd msg )
init { onChange } =
    ( initModel
    , Cmd.none
    )


initModel : Model
initModel =
    { email = ""
    , password = ""
    , errorMessages = []
    , isDisabled = False
    }


-- UPDATE

type alias UpdateOptions msg =
    { apiUrl : Url
    , onLoggedIn : User -> msg
    , onChange : Msg -> msg
    }


type Msg
    = ChangedEmail String
    | ChangedPassword String
    | SubmittedForm
    | GotLoginResponse (Result (Api.Error (List String)) User)


update : UpdateOptions msg -> Msg -> Model -> ( Model, Cmd msg )
update options msg model =
    case msg of
        ChangedEmail email ->
            ({ model | email = email }, Cmd.none)

        ChangedPassword password ->
            ({ model | password = password }, Cmd.none)

        SubmittedForm ->
            validate model
                |> V.withValidation
                    { onSuccess =
                        \{ email, password } ->
                            ( { model | errorMessages = [], isDisabled = True }
                            , Login.login
                                options.apiUrl
                                { email = email
                                , password = password
                                , onResponse = GotLoginResponse
                                }
                                |> Cmd.map options.onChange
                            )
                    , onFailure =
                        \errorMessages ->
                            ( { model | errorMessages = errorMessages }
                            , Cmd.none
                            )
                    }

        GotLoginResponse result ->
            Api.handleFormResponse
                (\user ->
                    ( initModel
                    , Task.dispatch (options.onLoggedIn user)
                    )
                )
                model
                result


type alias ValidatedFields =
    { email : Email
    , password : Password
    }


validate : Model -> V.Validation ValidatedFields
validate { email, password } =
    V.succeed ValidatedFields
        |> V.apply (V.email email)
        |> V.apply (V.password password)


-- VIEW

type alias ViewOptions msg =
    { onChange : Msg -> msg
    }

view : ViewOptions msg -> Model -> B.Document msg
view { onChange } { email, password, errorMessages, isDisabled } =
    { title = "Login"
    , body =
        [ Layout.view
            { name = "auth"
            , role = Navigation.login
            , maybeHeader = Nothing
            }
            [ Column.viewSingle Column.ExtraSmall
                [ Login.view
                    { form =
                        { email = email
                        , password = password
                        , isDisabled = isDisabled
                        , onInputEmail = ChangedEmail
                        , onInputPassword = ChangedPassword
                        , onSubmit = SubmittedForm
                        }
                    , errorMessages = errorMessages
                    }
                ]
            ]
            |> H.map onChange
        ]
    }
