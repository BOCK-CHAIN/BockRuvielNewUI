import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Get activities
router.get('/activities', async (req, res) => {
  const { userId } = req.query;

  try {
    const { data, error } = await supabase
      .from('activity')
      .select('*, profiles!activity_user_id_fkey(username, profile_image_url)')
      .eq('target_user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
