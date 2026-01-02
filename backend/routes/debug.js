import express from 'express';
import { verifyJWT } from '../utils/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * Debug reel creation step by step
 */
router.post('/debug-create', verifyJWT, async (req, res) => {
  try {
    const userId = req.userId;
    const { caption, music, videoBase64 } = req.body;

    console.log('🔍 Debug: Starting reel creation');
    console.log('🔍 Debug: User ID:', userId);
    console.log('🔍 Debug: Request body:', { caption, music, hasVideoBase64: !!videoBase64 });

    // Step 1: Get user profile
    console.log('🔍 Debug: Step 1 - Getting user profile...');
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('username')
      .eq('id', userId)
      .single();

    if (profileError) {
      console.error('❌ Debug: Profile error:', profileError);
      return res.status(404).json({
        error: 'Profile not found',
        message: 'User profile does not exist',
        debug: profileError
      });
    }

    console.log('✅ Debug: Profile found:', profile);

    // Step 2: Test basic insert without video
    console.log('🔍 Debug: Step 2 - Testing basic insert...');
    const { data: reel, error: reelError } = await supabase
      .from('reels')
      .insert({
        user_id: userId,
        username: profile.username,
        video_url: 'test_url',
        caption: caption || null,
        music: music || null,
        likes_count: 0,
        comments_count: 0
      })
      .select()
      .single();

    if (reelError) {
      console.error('❌ Debug: Reel insert error:', reelError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to create reel',
        debug: reelError
      });
    }

    console.log('✅ Debug: Reel created successfully:', reel);

    // Step 3: Test the join query
    console.log('🔍 Debug: Step 3 - Testing join query...');
    const { data: fullReel, error: fetchError } = await supabase
      .from('reels')
      .select(`
        *,
        profiles!reels_user_id_fkey(username, profile_image_url)
      `)
      .eq('id', reel.id)
      .single();

    if (fetchError) {
      console.error('❌ Debug: Join query error:', fetchError);
      return res.status(500).json({
        error: 'Database error',
        message: 'Failed to fetch reel data',
        debug: fetchError
      });
    }

    console.log('✅ Debug: Full reel data fetched:', fullReel);

    res.json({
      success: true,
      message: 'Reel creation debug successful',
      reel: fullReel
    });

  } catch (error) {
    console.error('❌ Debug: Unexpected error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Debug failed',
      debug: error.message
    });
  }
});

/**
 * Test reels table structure
 */
router.get('/debug-table', async (req, res) => {
  try {
    console.log('🔍 Debug: Testing reels table structure...');
    
    // Test basic select
    const { data, error } = await supabase
      .from('reels')
      .select('*')
      .limit(1);

    if (error) {
      console.error('❌ Debug: Table select error:', error);
      return res.status(500).json({
        error: 'Table error',
        message: 'Failed to query reels table',
        debug: error
      });
    }

    console.log('✅ Debug: Table structure:', data);

    // Test table info
    const { data: tableInfo, error: infoError } = await supabase
      .from('information_schema.columns')
      .select('column_name, data_type, is_nullable')
      .eq('table_name', 'reels')
      .eq('table_schema', 'public');

    if (infoError) {
      console.error('❌ Debug: Table info error:', infoError);
    }

    res.json({
      success: true,
      message: 'Reels table structure debug',
      sampleData: data,
      tableInfo: tableInfo || null
    });

  } catch (error) {
    console.error('❌ Debug: Table structure error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Table structure debug failed',
      debug: error.message
    });
  }
});

export default router;