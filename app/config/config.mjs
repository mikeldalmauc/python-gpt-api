// File: config/config.mjs
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();
console.log('Loaded environment variables:', process.env);

const {
    DOMAIN,
    MONGO_INITDB_ROOT_USERNAME,
    MONGO_INITDB_ROOT_PASSWORD,
    MONGODB_DOCKER_PORT,
    MONGODB_DATABASE
} = process.env;

export const redisPassword = process.env.REDIS_PASSWORD;
export const redisHost = process.env.REDIS_HOST;
export const jwtSecret = process.env.JWT_SECRET;
export const mongoUri = `mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${DOMAIN}:${MONGODB_DOCKER_PORT}/${MONGODB_DATABASE}`;
export const sessionSecret = process.env.SESSION_SECRET;
export const adminPass = process.env.ADMIN_PASS;
export const port = process.env.PORT || 3000;