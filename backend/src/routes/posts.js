const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/authMiddleware');
const {
    getPosts,
    createPost,
    getUserPosts,
    toggleLike,
    addComment,
    getComments,
    deletePost
} = require('../controllers/posts');

// POST ROUTES
router.route('/')
    .get(getPosts)
    .post(protect, createPost);

router.route('/:postId')
    .delete(protect, deletePost);

router.route('/user/:userId')
    .get(getUserPosts);

// LIKE ROUTE
router.route('/:postId/like')
    .post(protect, toggleLike);

// COMMENT ROUTES
router.route('/:postId/comments')
    .get(getComments)
    .post(protect, addComment);

module.exports = router;