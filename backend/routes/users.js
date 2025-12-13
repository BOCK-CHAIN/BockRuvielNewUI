import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Get user profile
router.get('/users/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json(data);

  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user profile
router.put('/users/:id', async (req, res) => {
  const { id } = req.params;
  const { full_name, bio, profile_image_url } = req.body;

  try {
    const { data, error } = await supabase
      .from('profiles')
      .update({
        full_name,
        bio,
        profile_image_url,
        updated_at: new Date(),
      })
      .eq('id', id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(200).json(data);

  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
