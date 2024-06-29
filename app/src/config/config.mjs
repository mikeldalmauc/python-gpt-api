// File: config/config.mjs
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Load environment variables
dotenv.config();
//console.log('Loaded environment variables:', process.env);

const {
    DOMAIN,
    MONGO_INITDB_ROOT_USERNAME,
    MONGO_INITDB_ROOT_PASSWORD,
    MONGODB_DOCKER_PORT,
    MONGODB_DATABASE,
    MONGODB_TEST_DATABASE,
    MONGODB_HOST
} = process.env;

export const prefix = process.env.PREFIX;
export const redisPassword = process.env.REDIS_PASSWORD;
export const redisHost = process.env.REDIS_HOST;
export const jwtSecret = process.env.JWT_SECRET;
export const mongoUri = `mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${MONGODB_HOST}:${MONGODB_DOCKER_PORT}/${MONGODB_DATABASE}`;
export const sessionSecret = process.env.SESSION_SECRET;

export const appAdminEmail = process.env.ADMIN_EMAIL;
export const appAdminPass = process.env.ADMIN_PASS;

export const port = process.env.PORT || 3000;
export const mongoTestUri = `mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${MONGODB_HOST}:${MONGODB_DOCKER_PORT}/${MONGODB_TEST_DATABASE}`;