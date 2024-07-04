const { src, dest, watch, series, parallel } = require('gulp');

const sass = require('gulp-sass')(require('sass'));
const { exec } = require('child_process');

const cssFiles = 'src/scss/*.scss';
const nodeFiles = 'src/**/*.mjs';
const jsFiles = 'src/js/**/*.js';


function nodeTask(cb) {
    const server = exec('npx nodemon');

    server.stdout.on('data', function(data) {
        console.log(data.toString());
    });

    server.stderr.on('data', function(data) {
        console.error(data.toString());
    });

    server.on('exit', function(code) {
        console.log(`Server exited with code ${code}`);
    });

    cb();
}


function jsTask() {
    return src(jsFiles)
    .pipe(dest('public/js'));
}

// Task to compile SCSS files to CSS
function cssTask() {
    console.log('Running cssCompileTask...');
    return src(cssFiles)
        .pipe(sass().on('error', sass.logError))
        .pipe(dest('public/styles'));
}

function watchTask() {
    //Watch for changes in any SCSS or JS files, and run the scssTask,
    watch(jsFiles, jsTask);
    watch(nodeFiles, nodeTask);
    watch(cssFiles, cssTask);
}

// Export everything to run when you run 'gulp'
module.exports = {
    nodeTask,
    cssTask,
    jsTask,
    default: series(
        parallel(nodeTask, cssTask, jsTask),
        watchTask
    )
  };