
import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
    user: { type: String, required: true },
    message: { type: String, required: true },
    timestamp: { type: Date, default: Date.now }
  });
  
const channelSchema = new mongoose.Schema({
    id: { type: mongoose.SchemaTypes.String, required: true, index: true },
    messages: [messageSchema],
    archived: Boolean,
    owner: String,
    participants: [String],
});


const userSchema = new mongoose.Schema({
    name: String,
    email: { type: String, unique: true, required: true },
    password: String,
    role: String,
  });
  

const User = mongoose.model('User', userSchema);
const Channel = mongoose.model('Channel', channelSchema);


export {User, Channel};