import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import {appAdminEmail, appAdminPass} from '../../config/config.mjs'
import jwt from 'jsonwebtoken';


const userSchema = new mongoose.Schema({
  name: String,
  email:{ type: String, unique: true, required: true },
  password: String,
  role: String,
  conversationHistory: Array
});

const User = mongoose.model('User', userSchema);

async function initializeUser(name, email, password, role = 'user') {
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      name,
      email,
      password: hashedPassword,
      role,
      conversationHistory: []
    });

    await newUser.save();

    console.log('User created successfully');
  } catch (error) {
    console.error('Error creating user:', error);
  }
}

async function initAdminUser() {
  try {
    const adminExists = await User.findOne({ role: 'admin' });
    if (!adminExists) {
      await initializeUser('admin', appAdminEmail, appAdminPass, 'admin');
      console.log('Admin user initialized');
    } else {
      console.log('Admin user already exists');
    }
  } catch (error) {
    console.error('Error initializing admin user:', error);
  }
}

async function deleteUser(email) {
  try {
    await User.findOneAndDelete({ email: email });
    console.log('User deleted successfully');
  } catch (error) {
    console.error('Error deleting user:', error);
  }
}

async function readUser(email) {
  try {
    const user = await User.findOne({ email: email });
    if (user) {
      console.log('User data:', user);
      return user;
    } else {
      console.log('User not found');
    }
  } catch (error) {
    console.error('Error reading user:', error);
  }
}

async function updateUser(email, updatedData) {
  try {
    const user = await User.findOneAndUpdate({ email: email }, updatedData, { new: true });
    if (user) {
      console.log('User updated successfully:', user);
      return user;
    } else {
      console.log('User not found');
    }
  } catch (error) {
    console.error('Error updating user:', error);
  }
}

async function loginUser(email, password) {
  try {
    console.log(email);
    console.log(password);
    const user = await User.findOne({ email: email });
    if (!user) {
      throw new Error('User not found');
    }
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new Error('Invalid password');
    }

    //const jwtToken = jwt.sign({ email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: '1h' });
    return { user };
  } catch (error) {
    console.error('Error logging in:', error);
    throw error;
  }
}

export { initializeUser, initAdminUser, deleteUser, readUser, updateUser, loginUser };
