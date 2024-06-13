- [Install](#install)
- [Build the source code](#build-the-source-code)
- [Build the elm code](#build-the-elm-code)
- [Elm code reference](#elm-code-reference)


## Install

Run npm for required packages

```npm install```

Run for gulp client

```npm install --global gulp-cli```

Download the elm installer

https://guide.elm-lang.org/install/elm.html
    

## Build the source code

Source code is built and added to build folder using gulp command.

```gulp``` 

This command will run a live server and compile elm on changes.


## Build the elm code

The gulp task will run the following command to build the Elm code.

```elm make src/Main.elm --output build/main.js```

## Elm code reference

https://github.com/dwayne/elm-conduit