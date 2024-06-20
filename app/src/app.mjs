
import express from 'express';
import session from 'express-session';
import RedisStore  from 'connect-redis';
import path from 'path';
import { fileURLToPath } from 'url';

import redisClient from './middlewares/redisClient.mjs';
import connectDB from './middlewares/mongoClient.mjs';
import { sessionSecret, port, prefix } from './config/config.mjs';
import authenticateToken from './middlewares/jwtVerifier.mjs';
import { initializeUser, initAdminUser, loginUser } from './repository/mongo/userRepo.mjs'; // adjust the path as necessary


// __dirname polyfill for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Express app
const app = express();
app.use(express.json());

// Redis client should be started for session form middleware
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: true } // Set to true if using HTTPS
}));

// Connect mongo client
connectDB();

// Initialize admin user in mongo if not exists
initAdminUser();

// Configure template engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../views'));
console.log('Template engine configured');

// Routes
app.get('/', (req, res) => res.render('home'));

// Login route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const { jwt, user } = await loginUser(email, password);
    req.session.jwt = jwt;
    res.json({ message: 'Login successful', user });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

app.get('/profile', authenticateToken, (req, res) => {
    res.send(`Hello ${req.user.email}, your role is ${req.user.role}`);
});
  
// Example of setting session data
app.get('/setSessionData', authenticateToken, function(req, res) {
    req.session.username = 'John Doe';
    res.send('Session data set successfully!');
});
  
// Example of getting session data
app.get('/getSessionData', authenticateToken, function(req, res) {
    res.send('Username: ' + req.session.username);
});



// START SERVER allow restart 
let server;
function startServer() {
  server = app.listen(port, () => console.log(`Server running on port ${port}`));

  // Handle server shutdown gracefully
  process.on('SIGTERM', () => {
    if (server) {
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    }
  });

  process.on('SIGINT', () => {
    if (server) {
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    }
  });
}

startServer();

export { app };