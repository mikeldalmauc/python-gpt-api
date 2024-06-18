// redisClient.js

const Redis = require('ioredis');
import redisClient from '@middlewares/redisClient.mjs';


const USER_SESSION_PREFIX = 'user_session:';

// Función para escribir una sesión en Redis
async function writeSessionToRedis(userId, sessionData) {
    await redis.set(`${USER_SESSION_PREFIX}${userId}`, JSON.stringify(sessionData), 'EX', 3600);
}

// Función para leer una sesión desde Redis
async function readSessionFromRedis(userId) {
    const data = await redis.get(`${USER_SESSION_PREFIX}${userId}`);
    return data ? JSON.parse(data) : null;
}

// Función para eliminar una sesión de Redis
async function deleteSessionFromRedis(userId) {
    await redis.del(`${USER_SESSION_PREFIX}${userId}`);
}

module.exports = {
    writeSessionToRedis,
    readSessionFromRedis,
    deleteSessionFromRedis
};
