const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'ServicePro API running' });
});

app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

const dashboardRoutes = require('./routes/dashboard');
app.use('/api/dashboard', dashboardRoutes);

const announcementRoutes = require('./routes/announcements');
app.use('/api/announcements', announcementRoutes);

const userRoutes = require('./routes/users');
app.use('/api/users', userRoutes);


const verifyRoutes = require('./routes/verify');
app.use('/api/verify', verifyRoutes);


const chatRoutes = require('./routes/chat');
app.use('/api/chat', chatRoutes);

const profilePageRoutes = require('./routes/profile_page');
app.use('/api', profilePageRoutes);

const chatUserRoutes = require('./routes/chatuser');
app.use('/api/user-chat', chatUserRoutes);

const jobRoutes = require('./routes/jobs');
app.use('/api', jobRoutes);

const agoraRoutes = require('./routes/agora');
app.use('/api', agoraRoutes);

const chatV2Routes = require('./routes/chat_v2');
app.use('/api/chat-v2', chatV2Routes);

const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const mapsRoutes = require('./routes/maps');
app.use('/api/maps', mapsRoutes);

const earningsRoutes = require('./routes/earnings');
app.use('/api/earnings', earningsRoutes);

const reviewsRoutes = require('./routes/reviews');
app.use('/api/reviews', reviewsRoutes);

const reportRoutes = require('./routes/report');
app.use('/api/report', reportRoutes);










