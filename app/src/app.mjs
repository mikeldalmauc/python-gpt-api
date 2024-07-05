
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
import { initializeUser, initAdminUser, loginUser, deleteUser } from './repository/mongo/userRepo.mjs'; // adjust the path as necessary
import { debug } from 'console';
import { createAdminChannel, readChannels, readChannel, packMessage, updateChannel, addMessageToChannel} from './repository/mongo/chatRepo.mjs';

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
  cookie: { secure: false, httpOnly: true, maxAge: 1000 * 60 * 60 }, // 1 hora de duración
  activeChannel: null
}));

// Connect mongo client
connectDB();

// DATA CREATION
//_____________________________________________________________________________________

deleteUser("")
initAdminUser();
createAdminChannel();

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


// Login
//_____________________________________________________________________________________

// Login route
app.post('/login', async (req, res) => {

  console.log(req.body);
  const { email, password } = req.body;
  try {
    const { user } = await loginUser(email, password);

  // Save user to session
    req.session.user = user;
    req.session.options = readOptions(user)
    req.session.save();    

    res.status(200).json({ message: 'Login successful', user });
    console.log('Login successful');

  } catch (error) {
    res.status(400).json({ message: error.message });
    console.log('Login failed');
  }
});


app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
});


// Options
//_____________________________________________________________________________________

/**
 * Get user options, such as menu items, etc.
 * TODO extract data from mongo and save on redis for session usage
 * @param {Object} user
 * @returns {Object} options
 */
function readOptions(user) {

  let options = {};

  options.menuItems = [
    {id:"mi-0", text:"Chat", path:"c", icon:"chat", tooltiptext:"Chat with game characters."}
  , {id:"mi-1", text:"History", path:"h", icon:"history", tooltiptext:"View chat histories."}
  ];

  options.user = { 
    email: user.email,
    role: user.role,
    name: user.name
  };

  return options;
}

app.get('/dashboard', (req, res) => {
  res.render('dashboard', req.session.options);
  //res.render('dashboard', { user: user_data, title:"dashboard", menuItems: menuItems, section: section});
});


// CHAT
//_____________________________________________________________________________________

// Render Chat page with user options
app.get('/chat', async (req, res) => {

  try{
    let channels = await readChannels(req.session.user.email);
    console.log(channels);
    if(channels.length > 0) {
      req.session.activeChannel = channels[0].id;
      req.session.save();    

      res.render('chat', req.session.options);
    }else{
      res.render('chat', req.session.options);
    }
  }catch(error){
    res.render('chat', req.session.options);
  }
  
});

// Chat messages add
app.post('/'+prefix+'/chat', async (req, res) => {
  try{

    if(req.body != null && req.body != "" ) {
      console.log(req.session.activeChannel);
      addMessageToChannel(req.session.activeChannel, packMessage(req.session.user.email, req.body.message))
      .then(updatedChannel => {
          console.log('Updated Channel:', updatedChannel);
        }).catch(error => {
          console.error('Error:', error);
        });

      console.log("Adding message to channel");
    }else{
      console.log("Message not added to channel!!");
    }

    res.status(200).json(req.body);
  }catch(error){
    console.log(error);
    res.status(500).json({ message: "Error reading channels" });
  }

});

// Chat messages read
app.get('/'+prefix+'/chat', async (req, res) => {
  console.log(req.session.user.email);
  try{
    let channels = await readChannels(req.session.user.email);
    console.log(channels[0].id);
    if(channels.length > 0) {
      req.session.activeChannel = channels[0].id;
      req.session.save();    

      res.status(200).json(channels[0]);
    }else{
      res.status(400).json({ message: 'No channels found' });
    }
  }catch(error){
    res.status(500).json({ message: "Error reading channels" });
  }

});


// HISTORY
//_____________________________________________________________________________________

app.get('/history', (req, res) => {
  res.render('chat', req.session.options);
});





// Start server
//_____________________________________________________________________________________




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