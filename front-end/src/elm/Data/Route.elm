module Data.Route exposing
    ( Route(..)
    , fromUrl
    , logoutPath
    , pushUrl
    , toString
    )

import Browser.Navigation as BN
import Data.Username as Username exposing (Username)
import Url exposing (Url)
import Url.Builder as UB
import Url.Parser as UP exposing ((</>))


type Route
    = Home
    | Login


fromUrl : Url -> Maybe Route
fromUrl =
    UP.parse routeParser


routeParser : UP.Parser (Route -> a) a
routeParser =
    UP.oneOf
        [ UP.map Home UP.top
        , UP.map Login (UP.s "login")
        ]


usernameParser : UP.Parser (Username -> a) a
usernameParser =
    UP.custom "USERNAME" (Url.percentDecode >> Maybe.andThen Username.fromString)


redirectToHome : BN.Key -> Cmd msg
redirectToHome key =
    replaceUrl key Home


replaceUrl : BN.Key -> Route -> Cmd msg
replaceUrl key =
    toString >> BN.replaceUrl key


pushUrl : BN.Key -> Route -> Cmd msg
pushUrl key =
    toString >> BN.pushUrl key


toString : Route -> String
toString route =
    case route of
        Home ->
            UB.absolute [] []

        Login ->
            UB.absolute [ "login" ] []


logoutPath : String
logoutPath =
    UB.absolute [ "logout" ] []