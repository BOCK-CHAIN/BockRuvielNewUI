const postService = require('../services/posts');

exports.getPosts = async (req, res) => {
    try {
        const { postType, limit, offset } = req.query;
        const posts = await postService.getPosts(postType, limit, offset);
        res.json(posts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.createPost = async (req, res) => {
    try {
        const post = await postService.createPost(req.body, req.user.id);
        res.status(201).json(post);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getUserPosts = async (req, res) => {
    try {
        const { postType } = req.query;
        const posts = await postService.getUserPosts(req.params.userId, postType);
        res.json(posts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.toggleLike = async (req, res) => {
    try {
        const result = await postService.toggleLike(req.params.postId, req.user.id);
        res.json(result);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.addComment = async (req, res) => {
    try {
        const comment = await postService.addComment(req.params.postId, req.body, req.user.id);
        res.status(201).json(comment);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

exports.getComments = async (req, res) => {
    try {
        const comments = await postService.getComments(req.params.postId);
        res.json(comments);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.deletePost = async (req, res) => {
    try {
        await postService.deletePost(req.params.postId, req.user.id);
        res.status(204).send();
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};