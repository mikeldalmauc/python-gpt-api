
import express from 'express';
import session from 'express-session';
import RedisStore  from 'connect-redis';
import path from 'path';
import { fileURLToPath } from 'url';
import * as sass from 'sass';
import {redisClient} from './middlewares/redisClient.mjs';
import connectDB from './middlewares/mongoClient.mjs';
import { sessionSecret, port, prefix } from './config/config.mjs';
import authenticateToken from './middlewares/jwtVerifier.mjs';
import { initializeUser, initAdminUser, loginUser } from './repository/mongo/userRepo.mjs'; // adjust the path as necessary

// __dirname polyfill for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Initialize Express app
const app = express();

// Middleware to parse URL-encoded bodies (from HTML forms)
app.use(express.urlencoded({ extended: true })); // Or use body-parser: app.use(bodyParser.urlencoded({ extended: true }));

// Middleware to parse JSON bodies
app.use(express.json());

// Redis client should be started for session form middleware
// The session ID is stored as a cookie i
// By default, the session ID is saved in a cookie with the name connect.sid. 
// This cookie is used to identify and differentiate sessions between the server and the client.
await redisClient.connect();
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, httpOnly: true, maxAge: 1000 * 60 * 60 } // 1 hora de duración
}));

// Connect mongo client
connectDB();

// Initialize admin user in mongo if not exists
initAdminUser();

// Configure template engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
console.log('Template engine configured');

// Serve static files from public directory
console.log(path.join(__dirname, '..', 'public'));
app.use(express.static(path.join(__dirname,  '..', 'public')));

// Routes
app.get('/', (req, res) => {
  // crear nuevo objeto de sesión.
  if(req.session.key) {
    // el usuario ya ha iniciado sesión
    res.redirect('/dashboard');
  } else {
    // no se ha encontrado ninguna sesión, vaya a la página de inicio
    res.render("home", {title:"home"});
  }
});

// Login route
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const { user } = await loginUser(email, password);
    req.session.user = user; // Save user to session
    req.session.save(() => {
      res.redirect('/dashboard');
    });    
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// API Login route
app.post(prefix+'/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const { user } = await loginUser(email, password);
    req.session.user = user; // Save user to session
    req.session.save(() => {
      res.json({ message: 'Login successful', user });
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

function saveUserToSession(req, user, callback){
  req.session.user = user; // Save user to session
}
app.get('/dashboard', (req, res) => {
  console.log(req.cookies);
  console.log(req.session);
  console.log(req.session.user);

  const section = req.query.section || 'chat';
  res.render('dashboard', { user: req.session.user, title:"dashboard", section: section});
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
  let handleExit = () => {
    if (server) {
      server.close(() => {
        console.log('Server closed');
        process.exit(0);
      });
    }
  }

  // Handle server shutdown gracefully
  process.on('SIGINT', handleExit);
  process.on('SIGTERM', handleExit);
  process.on('SIGQUIT', handleExit);
}

startServer();

export { app };