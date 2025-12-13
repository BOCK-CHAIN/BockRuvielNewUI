import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Create Post
router.post('/posts', async (req, res) => {
  const { userId, username, caption, imageUrl, postType } = req.body;

  try {
    const { data, error } = await supabase
      .from('posts')
      .insert({
        user_id: userId,
        username: username,
        caption,
        image_url: imageUrl,
        post_type: postType,
        likes_count: 0,
        comments_count: 0,
      })
      .select()
      .single();

    if (error) throw error;

    await supabase.rpc('increment_posts_count', { user_id: userId });

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get Posts
router.get('/posts', async (req, res) => {
  const { limit = 20, offset = 0, postType } = req.query;

  try {
    let query = supabase
      .from('posts')
      .select(`
        *,
        profiles!posts_user_id_fkey(username, profile_image_url),
        likes(user_id),
        comments(id)
      `);

    if (postType) {
      query = query.eq('post_type', postType);
    }

    const { data, error } = await query
      .order('created_at', { ascending: false })
      .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get User Posts
router.get('/users/:userId/posts', async (req, res) => {
    const { userId } = req.params;
    const { postType } = req.query;

    try {
        let query = supabase
            .from('posts')
            .select(`
              *,
              profiles!posts_user_id_fkey(username, profile_image_url),
              likes(user_id),
              comments(id)
            `)
            .eq('user_id', userId);

        if (postType) {
            query = query.eq('post_type', postType);
        }

        const { data, error } = await query.order('created_at', { ascending: false });

        if (error) throw error;

        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


// Toggle Like
router.post('/posts/:postId/like', async (req, res) => {
  const { postId } = req.params;
  const { userId } = req.body;

  try {
    const { data: existingLike, error: selectError } = await supabase
      .from('likes')
      .select()
      .eq('post_id', postId)
      .eq('user_id', userId)
      .maybeSingle();

    if (selectError) throw selectError;

    if (existingLike) {
      await supabase.from('likes').delete().match({ post_id: postId, user_id: userId });
      await supabase.rpc('decrement_likes_count', { post_id: postId });
      res.status(200).json({ liked: false });
    } else {
      await supabase.from('likes').insert({ post_id: postId, user_id: userId });
      await supabase.rpc('increment_likes_count', { post_id: postId });
      res.status(200).json({ liked: true });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add Comment
router.post('/posts/:postId/comments', async (req, res) => {
  const { postId } = req.params;
  const { userId, username, comment } = req.body;

  try {
    const { data, error } = await supabase
      .from('comments')
      .insert({ post_id: postId, user_id: userId, username, comment })
      .select()
      .single();

    if (error) throw error;

    await supabase.rpc('increment_comments_count', { post_id: postId });

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get Comments
router.get('/posts/:postId/comments', async (req, res) => {
    const { postId } = req.params;

    try {
        const { data, error } = await supabase
            .from('comments')
            .select(`
                *,
                profiles!comments_user_id_fkey(username, profile_image_url)
            `)
            .eq('post_id', postId)
            .order('created_at', { ascending: true });

        if (error) throw error;

        res.status(200).json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete Post
router.delete('/posts/:postId', async (req, res) => {
    const { postId } = req.params;
    const { userId } = req.body; // Assuming userId is sent in the body for verification

    try {
        // Verify ownership
        const { data: post, error: postError } = await supabase
            .from('posts')
            .select('user_id, image_url')
            .eq('id', postId)
            .single();

        if (postError) throw postError;
        if (post.user_id !== userId) {
            return res.status(403).json({ error: 'You are not authorized to delete this post' });
        }

        // Delete post (supabase should handle cascading deletes)
        const { error: deleteError } = await supabase.from('posts').delete().eq('id', postId);
        if (deleteError) throw deleteError;

        // Decrement user's post count
        await supabase.rpc('decrement_posts_count', { user_id: userId });

        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});



export default router;
