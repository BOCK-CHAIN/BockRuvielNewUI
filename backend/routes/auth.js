import express from 'express';
import { verifyJWT } from '../utils/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * GET /api/auth/me
 * Get current user profile with authentication
 * Requires valid Supabase JWT token
 */
router.get('/me', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;

    // Fetch user profile from Supabase
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      console.error('❌ Profile fetch error:', error);
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    // Return user data (excluding sensitive fields)
    res.json({
      user: {
        id: req.user.id,
        email: req.user.email,
        email_verified: req.user.email_confirmed_at != null,
        created_at: req.user.created_at,
        updated_at: req.user.updated_at
      },
      profile: {
        id: profile.id,
        username: profile.username,
        full_name: profile.full_name,
        bio: profile.bio,
        profile_image_url: profile.profile_image_url,
        followers_count: profile.followers_count || 0,
        following_count: profile.following_count || 0,
        posts_count: profile.posts_count || 0,
        created_at: profile.created_at,
        updated_at: profile.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Auth me endpoint error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch user profile'
    });
  }
});

/**
 * GET /api/auth/profile/:id
 * Get public profile information for any user
 * Does not require authentication (public endpoint)
 */
router.get('/profile/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'User ID must be a valid UUID'
      });
    }

    // Fetch public profile data
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, username, full_name, bio, profile_image_url, followers_count, following_count, posts_count, created_at')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist'
      });
    }

    res.json(profile);
  } catch (error) {
    console.error('❌ Public profile fetch error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch public profile'
    });
  }
});

export default router;