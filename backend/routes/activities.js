import express from 'express';
import { verifyJWT, optionalJWT } from '../utils/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * Get activities for current user
 * GET /api/activities
 */
router.get('/', verifyJWT, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const { limit = 50 } = req.query;

    // Fetch activities where user is either target or actor
    const orFilter = `target_user_id.eq.${currentUserId},user_id.eq.${currentUserId}`;

    const { data: activities, error } = await supabase
      .from('activities')
      .select(`
        *,
        profiles!activities_user_id_fkey(username, profile_image_url),
        posts(image_url)
      `)
      .or(orFilter)
      .order('created_at', { ascending: false })
      .limit(parseInt(limit));

    if (error) {
      throw error;
    }

    res.json({
      activities: activities || []
    });

  } catch (error) {
    console.error('❌ Get activities error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Create a new activity
 * POST /api/activities
 */
router.post('/', verifyJWT, async (req, res) => {
  try {
    const currentUserId = req.userId;
    const { type, targetUserId, postId, commentText } = req.body;

    // Validate activity type
    const validTypes = ['like', 'comment', 'follow', 'mention'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid activity type'
      });
    }

    // Generate activity ID
    const activityId = crypto.randomUUID();

    const { data: activity, error } = await supabase
      .from('activities')
      .insert({
        id: activityId,
        user_id: currentUserId,
        target_user_id: targetUserId,
        type,
        post_id: postId,
        comment_text: commentText
      })
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json({
      message: 'Activity created successfully',
      activity
    });

  } catch (error) {
    console.error('❌ Create activity error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * Delete an activity
 * DELETE /api/activities/:id
 */
router.delete('/:id', verifyJWT, async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.userId;

    const { error } = await supabase
      .from('activities')
      .delete()
      .eq('id', id)
      .eq('user_id', currentUserId); // Only allow users to delete their own activities

    if (error) {
      throw error;
    }

    res.json({
      message: 'Activity deleted successfully'
    });

  } catch (error) {
    console.error('❌ Delete activity error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

export default router;