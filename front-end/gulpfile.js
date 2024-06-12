const { src, dest, watch, series, parallel } = require('gulp');
const exec = require('gulp-exec');

const browserSync = require('browser-sync').create();

const htmlFiles = 'src/html/**/*.html';
const elmFiles = 'src/elm/**/*.elm';
const assets = 'assets/meta/**';

browserSync.init({
    server: {
        baseDir: "./build",
    }
});
    
function elmTask() {
    return src('.')
    .pipe(exec('elm make src/elm/Main.elm --output build/main.js')) // Put everything in the build directory
    //.pipe(exec('elm make src/Main.elm --optimize --output build/main.js')) // Put everything in the build directory
    //.pipe(exec('uglifyjs build/main.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle --output build/main.min.js')) // Put everything in the build directory
    .pipe(browserSync.stream()); // Update the browser
}

// Gulp task to copy HTML files to output directory
function htmlTask(){
    return src(htmlFiles)
    .pipe(dest('build')) // Put everything in the build directory
    .pipe(browserSync.stream());
}

// Gulp task to copy HTML files to output directory
function assetsTask(){
    return src(assets)
    .pipe(dest('build/assets')) // Put everything in the build directory
    .pipe(browserSync.stream());
}

function watchTask() {
    // Watch for changes in any SCSS or JS files, and run the scssTask,
    watch(
        [elmFiles, htmlFiles, assets],
        series(
            parallel(assetsTask, htmlTask, elmTask)
        )
    );
}

// Export everything to run when you run 'gulp'
module.exports = {
    default: series(
        parallel(elmTask, assetsTask, htmlTask),
        watchTask
    )
  };