import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Get messages
router.get('/messages', async (req, res) => {
  const { chatId } = req.query;

  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*, profiles(*)')
      .eq('chat_id', chatId)
      .order('created_at');

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send message
router.post('/messages', async (req, res) => {
  const { chatId, userId, content } = req.body;

  try {
    const { data, error } = await supabase
      .from('messages')
      .insert([{ chat_id: chatId, user_id: userId, content: content }]);

    if (error) throw error;

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
