const { src, dest, watch, series, parallel } = require('gulp');
const exec = require('gulp-exec');
const sass = require('gulp-sass')(require('sass'));

const cssFiles = 'src/scss/*.scss';
const jsFiles = 'src/**/*.mjs';

function jsTask() {
    return src('.')
    .pipe(exec('npx nodemon')) // Run node server
    //.pipe(browserSync.stream()); // Update the browser
    .pipe(exec.reporter());
}


// Task to compile SCSS files to CSS
function cssTask() {
    console.log('Running cssCompileTask...');
    return src(cssFiles)
        .pipe(sass().on('error', sass.logError))
        .pipe(dest('public/styles'));
}

function watchTask() {
    // Watch for changes in any SCSS or JS files, and run the scssTask,
    // watch(
    //     [jsFiles, cssFiles],
    //     series(
    //         parallel(jsTask, cssTask)
    //     )
    // );

    watch(jsFiles, jsTask);
    watch(cssFiles, cssTask);
}

// Export everything to run when you run 'gulp'
module.exports = {
    default: series(
        parallel(jsTask, cssTask),
        watchTask
    )
    ,cssTask
  };