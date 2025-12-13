
import express from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = express.Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// GET /api/activities
router.get('/activities', async (req, res) => {
  const { userId, limit = 50 } = req.query;

  try {
    const orFilter = `target_user_id.eq.${userId},user_id.eq.${userId}`;

    const { data, error } = await supabase
      .from('activities')
      .select(`
        *,
        profiles!activities_user_id_fkey(username, profile_image_url),
        posts(image_url)
      `)
      .or(orFilter)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching activities' });
  }
});

// POST /api/activities
router.post('/activities', async (req, res) => {
  const { userId, targetUserId, type, postId, commentText } = req.body;

  try {
    const { data, error } = await supabase
      .from('activities')
      .insert([
        {
          user_id: userId,
          target_user_id: targetUserId,
          type,
          post_id: postId,
          comment_text: commentText,
        },
      ]);

    if (error) {
      throw error;
    }

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: 'Error creating activity' });
  }
});

export default router;
