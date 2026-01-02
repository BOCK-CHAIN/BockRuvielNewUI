import express from 'express';
import { verifyJWT } from '../utils/auth.js';
import supabase from '../utils/auth.js';

const router = express.Router();

/**
 * Test database connection
 */
router.get('/test-db', async (req, res) => {
  try {
    // Test basic database query
    const { data, error } = await supabase
      .from('profiles')
      .select('count')
      .limit(1);

    if (error) {
      console.error('❌ Database test error:', error);
      return res.status(500).json({
        error: 'Database connection failed',
        message: error.message
      });
    }

    res.json({
      status: 'Database connection successful',
      data: data
    });
  } catch (error) {
    console.error('❌ Database test error:', error);
    res.status(500).json({
      error: 'Database test failed',
      message: error.message
    });
  }
});

/**
 * Test reels table existence
 */
router.get('/test-reels', async (req, res) => {
  try {
    // Test if reels table exists
    const { data, error } = await supabase
      .from('reels')
      .select('count')
      .limit(1);

    if (error) {
      console.error('❌ Reels table test error:', error);
      return res.status(500).json({
        error: 'Reels table not found or inaccessible',
        message: error.message
      });
    }

    res.json({
      status: 'Reels table accessible',
      data: data
    });
  } catch (error) {
    console.error('❌ Reels table test error:', error);
    res.status(500).json({
      error: 'Reels table test failed',
      message: error.message
    });
  }
});

export default router;