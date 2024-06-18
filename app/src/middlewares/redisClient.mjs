// File: redisClient.mjs
import redis from 'redis';
import { redisPassword, redisHost } from '../config/config.mjs';

console.log(redisHost);

const redisClient = redis.createClient({
    url: `redis://${redisHost}:6379`,
    password: redisPassword,
});

redisClient.on('connect', () => {
    console.log('Connected to Redis');
});

redisClient.on('error', (err) => {
    console.error('Redis error:', err);
});

export default redisClient;