// File: userInit.mjs
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import redisClient from '../middlewares/redisClient.mjs';

const initializeUser = async (email, password, role) => {
    const user = {
        email,
        passwordHash: await bcrypt.hash(password, 10),
        role,
        jwt: jwt.sign({ email, role }, process.env.JWT_SECRET, { expiresIn: '1h' })
    };
    await redisClient.set(email, JSON.stringify(user), (err, res) => {
        if (err) {
            console.error('Error initializing user in Redis:', err);
        } else {
            console.log('User initialized in Redis:', res);
        }
    });
};

async function initAdminUser() {
    try {
        const adminExists = await redisClient.exists('adminUser');
        if (!adminExists) {
            await redisClient.set('adminUser', JSON.stringify({ username: 'admin', password: 'adminpass' }));
            console.log('Admin user initialized');
        } else {
            console.log('Admin user already exists');
        }
    } catch (error) {
        console.error('Error initializing admin user:', error);
    }
}

export { initializeUser, initAdminUser };
