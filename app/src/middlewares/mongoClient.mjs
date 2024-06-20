import mongoose from 'mongoose';
import { mongoUri } from '../config/config.mjs';

// Connect to MongoDB
const connectDB = async () => {
    try {
        console.log(mongoUri+"?authSource=admin");
        await mongoose.connect(mongoUri+"?authSource=admin", {
        });
        console.log('Database is connected');
    } catch (err) {
        console.error('Error connecting to the database:', err);
        process.exit(1);
    }
};

export default connectDB;
