
import express from 'express';
import session from 'express-session';
import passport from 'passport';
import bodyParser from 'body-parser';
import RedisStore  from 'connect-redis';
import path from 'path';
import morgan from 'morgan';
import { fileURLToPath } from 'url';

import redisClient from './middlewares/redisClient.mjs';
import { initAdminUser } from './utils/userInit.mjs';
import { sessionSecret, port } from './config/config.mjs';
import authRoutes from './routes/auth.mjs';

// __dirname polyfill for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Express app
const app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(passport.initialize());
app.use(passport.session());
app.use(morgan('dev')); // Logging middleware

// Configure template engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
console.log('Template engine configured');

// Routes

app.use('/auth', authRoutes);
//app.use('/api', apiRoutes);

app.get('/', (req, res) => res.render('home'));
//app.get('/chat', (req, res) => res.render('chat'));

app.listen(port, () => console.log(`Server running on port ${port}`));

redisClient.connect();

initAdminUser();

export { app };