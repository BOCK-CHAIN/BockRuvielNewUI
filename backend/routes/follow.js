
import express from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = express.Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// POST /api/follow
router.post('/follow', async (req, res) => {
  const { followerId, followingId } = req.body;

  try {
    // Check if already following
    const { data: existing, error: existingError } = await supabase
      .from('follows')
      .select()
      .eq('follower_id', followerId)
      .eq('following_id', followingId)
      .maybeSingle();

    if (existingError) {
      throw existingError;
    }

    if (existing) {
      return res.status(200).send('Already following');
    }

    // Create follow relationship
    const { error: insertError } = await supabase.from('follows').insert({
      follower_id: followerId,
      following_id: followingId,
    });

    if (insertError) {
      throw insertError;
    }

    // Update follower and following counts
    await supabase.rpc('increment_followers_count', { user_id: followingId });
    await supabase.rpc('increment_following_count', { user_id: followerId });

    res.status(201).send('Followed successfully');
  } catch (error) {
    res.status(500).json({ error: 'Error following user' });
  }
});

// POST /api/unfollow
router.post('/unfollow', async (req, res) => {
  const { followerId, followingId } = req.body;

  try {
    // Delete follow relationship
    const { error } = await supabase
      .from('follows')
      .delete()
      .eq('follower_id', followerId)
      .eq('following_id', followingId);

    if (error) {
      throw error;
    }

    // Update follower and following counts
    await supabase.rpc('decrement_followers_count', { user_id: followingId });
    await supabase.rpc('decrement_following_count', { user_id: followerId });

    res.status(200).send('Unfollowed successfully');
  } catch (error) {
    res.status(500).json({ error: 'Error unfollowing user' });
  }
});

// GET /api/is-following
router.get('/is-following', async (req, res) => {
  const { followerId, followingId } = req.query;

  try {
    const { data, error } = await supabase
      .from('follows')
      .select()
      .eq('follower_id', followerId)
      .eq('following_id', followingId)
      .maybeSingle();

    if (error) {
      throw error;
    }

    res.json({ isFollowing: data != null });
  } catch (error) {
    res.status(500).json({ error: 'Error checking follow status' });
  }
});

// GET /api/followers/:userId
router.get('/followers/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const { data, error } = await supabase
      .from('follows')
      .select('profiles!follows_follower_id_fkey(*)')
      .eq('following_id', userId);

    if (error) {
      throw error;
    }

    res.json(data.map((item) => item.profiles));
  } catch (error) {
    res.status(500).json({ error: 'Error fetching followers' });
  }
});

// GET /api/following/:userId
router.get('/following/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const { data, error } = await supabase
      .from('follows')
      .select('profiles!follows_following_id_fkey(*)')
      .eq('follower_id', userId);

    if (error) {
      throw error;
    }

    res.json(data.map((item) => item.profiles));
  } catch (error) {
    res.status(500).json({ error: 'Error fetching following' });
  }
});

// GET /api/suggested-users
router.get('/suggested-users', async (req, res) => {
    const { userId, limit = 10 } = req.query;

    try {
        // Get users not followed by current user
        const { data: following, error: followingError } = await supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', userId);

        if (followingError) {
            throw followingError;
        }

        const followingIds = following.map((f) => f.following_id);
        followingIds.push(userId);

        const { data, error } = await supabase
            .from('profiles')
            .select()
            .not('id', 'in', `(${followingIds.join(',')})`)
            .order('followers_count', { ascending: false })
            .limit(limit);

        if (error) {
            throw error;
        }

        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Error fetching suggested users' });
    }
});

export default router;
