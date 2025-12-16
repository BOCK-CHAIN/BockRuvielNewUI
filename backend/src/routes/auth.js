const express = require('express');
const router = express.Router();
const { signup, login, logout, getMe } = require('../controllers/auth');
const { protect } = require('../middlewares/authMiddleware');

router.post('/signup', signup);
router.post('/login', login);
router.post('/logout', protect, logout);
router.get('/me', protect, getMe);

module.exports = router;