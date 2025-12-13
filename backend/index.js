import express from 'express';
import cors from 'cors';
import 'dotenv/config';

import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import postRoutes from './routes/post.js';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Use routes
app.use('/api', authRoutes);
app.use('/api', userRoutes);
app.use('/api', postRoutes);

app.get('/', (req, res) => {
  res.send('Hello from the backend!');
});

app.listen(port, () => {
  console.log(`Backend listening at http://localhost:${port}`);
});
