import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import { appAdminEmail, appAdminPass } from '../../config/config.mjs';

import jwt from 'jsonwebtoken';
import {User, Channel} from './schema.mjs';


async function createAdminChannel(){
  try {
    let user = await User.findOne({ email: appAdminEmail });
    const newChannel = new Channel({
      id: 'channel-' + Math.random().toString(36), // Generate a more unique random string
      owner: user._id,
      participants: [user._id],
      messages: [packMessage(appAdminEmail, 'Welcome to the admin channel')],
      archived: false,
    });
    await newChannel.save();
    
    console.log('Admin channel created successfully');
  }catch (error) {
    console.error('Error creating admin channel:', error);
  }

}

function packMessage(user, message){
  return {
    user: user,
    message: message,
    timestamp: Date.now()
  }
}

async function createChannel(user) {
  try {
    let user = await User.findOne({ email});
    const newChannel = new Channel({
      id: 'channel-' + Math.random().toString(36), // Generate a more unique random string
      owner: user._id,
      participants: [user._id],
      messages: [],
      archived: false,
    });
    await newChannel.save();
    
    console.log('Channel created successfully');
  } catch (error) {
    console.error('Error creating channel:', error);
  }

}

async function readChannels(userEmail) {
  try {
    // Find the user by email
    const user = await User.findOne({ email: userEmail });
    if (!user) {
      throw new Error('User not found');
    }

    // Find channels where the user is either the owner or a participant
    const channels = await Channel.find({
      $or: [
        { owner: user._id.toString() },
        { participants: user._id.toString() }
      ]
    });

    //console.log('Channels found:', channels);
    return channels;
  } catch (error) {
    console.error('Error finding channels:', error);
    throw error;
  }
}

async function readChannel(channelId) {
  try {
    const channel = await Channel.findOne({ id: channelId });
    if (!channel) {
      console.log('Channel not found');
    } else {
      console.log('Channel found:', channel);
    } 
    return channel;
  }
  catch (error) {
    console.error('Error reading channel:', error);
  }
}

async function updateChannel(channelId, updatedData) {
  try {
    const channel = await Channel.findOneAndUpdate({ id: channelId }, updatedData, { new: true });
    if (!channel) {
      console.log('Channel not found');
    } else {
      console.log('Channel updated successfully:', channel);
    }
    return channel;
  }
  catch (error) {
    console.error('Error updating channel:', error);
  }
}


async function addMessageToChannel(channelId, newMessage) {
  try {
    // const id = new mongoose.Types.ObjectId(channelId);
    // if (!mongoose.Types.ObjectId.isValid(id)) {
    //   console.log('Invalid channel ID : ' + id );
    //   return null;
    // }

    const channel = await Channel.findOneAndUpdate(
      { id: channelId },
      { $push: { messages: newMessage } },
      { new: true, useFindAndModify: false }
    );

    if (!channel) {
      console.log('Channel not found');
      return null;
    } else {
      console.log('Channel updated successfully:', channel);
      return channel;
    }
  } catch (error) {
    console.error('Error updating channel:', error);
    throw error;
  }
}






export {createChannel, readChannels, readChannel, createAdminChannel, packMessage, updateChannel, addMessageToChannel};