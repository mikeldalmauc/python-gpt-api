// File: redisClient.mjs
import redis from 'redis';
import { redisPassword, redisHost } from '../config/config.mjs';

const redisClient = redis.createClient({
    host: redisHost,
    port: 6379,
    password: redisPassword,
});

redisClient.on('connect', () => {
    console.log('Connected to Redis');
});

redisClient.on('error', (err) => {
    console.error('Redis error:', err);
});

export default redisClient;