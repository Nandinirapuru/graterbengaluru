const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5433;

/* =======================
   MIDDLEWARE
======================= */
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

/* =======================
   MONGODB CONNECTION
======================= */
mongoose.connect(process.env.MONGO_URL, {
  serverSelectionTimeoutMS: 5000
})
.then(() => console.log("MongoDB connected ✅"))
.catch(err => console.error("MongoDB connection error ❌", err.message));

/* =======================
   USER SCHEMA
======================= */
const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  mobile: {
    type: String,
    required: true,
    unique: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const User = mongoose.model('User', UserSchema);

/* =======================
   CONTACT SCHEMA
======================= */
const ContactSchema = new mongoose.Schema({
  name: String,
  email: String,
  phone: String,
  message: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const Contact = mongoose.model('Contact', ContactSchema);

/* =======================
   ROUTES – PAGES
======================= */

// Login page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

// Signup page
app.get('/signup', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'signup.html'));
});

// Dashboard
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

/* =======================
   SIGNUP (NAME + MOBILE)
======================= */
app.post('/signup', async (req, res) => {
  try {
    const { name, mobile } = req.body;

    if (!name || !mobile) {
      return res.send(`<script>alert("All fields required ❌"); window.history.back();</script>`);
    }

    const existingUser = await User.findOne({ mobile });
    if (existingUser) {
      return res.send(`<script>alert("Mobile number already registered ❌"); window.history.back();</script>`);
    }

    await User.create({ name, mobile });

    res.send(`<script>alert("Signup successful ✅"); window.location.href='/';</script>`);
  } catch (err) {
    res.send(`<script>alert("Signup error ❌ ${err.message}"); window.history.back();</script>`);
  }
});

/* =======================
   LOGIN (MOBILE ONLY)
======================= */
app.post('/login', async (req, res) => {
  try {
    const { mobile } = req.body;

    if (!mobile) {
      return res.send(`<script>alert("Mobile number required ❌"); window.history.back();</script>`);
    }

    const user = await User.findOne({ mobile });
    if (!user) {
      return res.send(`<script>alert("User not found ❌"); window.history.back();</script>`);
    }

    res.redirect('/dashboard');
  } catch (err) {
    res.send(`<script>alert("Login error ❌ ${err.message}"); window.history.back();</script>`);
  }
});

/* =======================
   CONTACT FORM
======================= */
app.post('/contact', async (req, res) => {
  try {
    const { name, email, phone, message } = req.body;

    await Contact.create({ name, email, phone, message });

    res.json({ success: true, message: "Message sent successfully ✅" });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to send message ❌" });
  }
});

/* =======================
   ADMIN – VIEW MESSAGES
======================= */
app.get('/admin/messages', async (req, res) => {
  try {
    const messages = await Contact.find().sort({ createdAt: -1 });
    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: "Error fetching messages ❌" });
  }
});

/* =======================
   START SERVER
======================= */
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT} 🚀`);
});
