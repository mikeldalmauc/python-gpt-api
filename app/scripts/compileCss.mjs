import * as sass from 'sass';
import fs from 'fs';
import path from 'path';
import { cssOutputFilename, scssFilename } from '../src/config/config.mjs';

// Compilar SCSS a CSS
sass.compileAsync(scssFilename)
    .then(result => {
        // Crear directorio si no existe
        const outputDir = path.dirname(cssOutputFilename);
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        // Escribir el CSS compilado en el archivo
        fs.writeFile(cssOutputFilename, result.css, (err) => {
            if (err) {
                console.error('Error writing CSS file:', err);
            } else {
                console.log('CSS file written successfully:', cssOutputFilename);
            }
        });
    })
    .catch(error => {
        console.error('Error compiling SCSS:', error);
    });
