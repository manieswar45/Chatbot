const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');
const { pipeline } = require('@xenova/transformers');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');

dotenv.config();

// Initialize express app
const app = express();
const port = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Set up rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', apiLimiter);

// Database connection
const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/chatbot';
const client = new MongoClient(uri);

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden' });
    req.user = user;
    next();
  });
};

// Connect to database
async function connectToDatabase() {
  try {
    await client.connect();
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
  }
}
connectToDatabase();

// Initialize model
let model;
async function loadModel() {
  try {
    // Using Hugging Face's pipeline for text generation
    // You can replace this with your preferred model
    model = await pipeline('text-generation', 'distilgpt2');
    console.log('Model loaded successfully');
  } catch (error) {
    console.error('Error loading model:', error);
  }
}
loadModel();

// Save chat message to database
async function saveMessage(userId, message, response) {
  try {
    const database = client.db('chatbot');
    const conversations = database.collection('conversations');
    
    await conversations.insertOne({
      userId,
      userMessage: message,
      botResponse: response,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Error saving message:', error);
  }
}

// API Routes
app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }
  
  try {
    // Process with model
    if (!model) {
      return res.status(503).json({ error: 'Model not loaded yet' });
    }
    
    const result = await model(message, {
      max_new_tokens: 100,
      temperature: 0.7
    });
    
    const botResponse = result[0].generated_text;
    
    // Save message if user is authenticated
    if (req.user) {
      await saveMessage(req.user.id, message, botResponse);
    }
    
    return res.json({ message: botResponse });
  } catch (error) {
    console.error('Error processing message:', error);
    return res.status(500).json({ error: 'Error processing message' });
  }
});

// User routes
app.post('/api/register', async (req, res) => {
  // User registration logic
});

app.post('/api/login', async (req, res) => {
  // User login logic and JWT token generation
});

// Protected route example
app.get('/api/history', authenticateToken, async (req, res) => {
  // Get user chat history
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});