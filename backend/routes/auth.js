import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// User Sign-Up
router.post('/auth/signup', async (req, res) => {
  const { email, password, username, full_name } = req.body;

  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          username,
          full_name: full_name || '',
        },
      },
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    // The `data` object contains user and session information.
    // The trigger in Supabase should handle profile creation.
    res.status(201).json(data);

  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// User Sign-In
router.post('/auth/signin', async (req, res) => {
  const { email, password } = req.body;

  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(200).json(data);

  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
