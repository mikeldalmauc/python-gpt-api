// File: routes/auth.mjs
import express from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { Strategy as JwtStrategy, ExtractJwt } from 'passport-jwt';
import redisClient from '../middlewares/redisClient.mjs'; // Import the centralized Redis client

const router = express.Router();

const jwtOptions = {
    jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
    secretOrKey: process.env.JWT_SECRET,
};

passport.use(new JwtStrategy(jwtOptions, (payload, done) => {
    redisClient.get(payload.email, (err, reply) => {
        if (err) {
            return done(err, false);
        }
        if (reply) {
            const user = JSON.parse(reply);
            return done(null, user);
        } else {
            return done(null, false);
        }
    });
}));

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    redisClient.get(email, (err, reply) => {
        if (err) {
            return res.status(500).json({ message: 'Internal server error' });
        }
        if (reply) {
            const user = JSON.parse(reply);
            if (bcrypt.compareSync(password, user.passwordHash)) {
                const payload = { email: user.email, role: user.role };
                const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1h' });
                res.json({ token });
            } else {
                res.status(401).json({ message: 'Invalid email or password' });
            }
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    });
});

export default router;
