import express from 'express';
import mongoose from 'mongoose';
import bodyParser from 'body-parser';
import connectDB from './middlewares/mongoClient.mjs';


// Fetch all chat history
app.get('/chat/history', async (req, res) => {
  try {
    const chats = await Chat.find({}, 'id'); // Fetch only the id field
    res.json(chats);
  } catch (error) {
    res.status(500).send('Error fetching chat history');
  }
});

// Fetch specific chat by ID
app.get('/chat/history/:id', async (req, res) => {
  try {
    const chat = await Chat.findOne({ id: req.params.id });
    if (chat) {
      res.json(chat);
    } else {
      res.status(404).send('Chat not found');
    }
  } catch (error) {
    res.status(500).send('Error fetching chat data');
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
