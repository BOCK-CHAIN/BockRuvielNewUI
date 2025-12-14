import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';
import multer from 'multer';

const router = Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);
const upload = multer({ storage: multer.memoryStorage() });

// Get stories
router.get('/stories', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('stories')
      .select('*, profiles(username, profile_image_url)')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Upload story
router.post('/stories', upload.single('story'), async (req, res) => {
  const { userId, storyType } = req.body;
  const file = req.file;

  if (!file) {
    return res.status(400).json({ error: 'No file uploaded.' });
  }

  const fileName = `${Date.now()}_${file.originalname}`;

  try {
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('stories')
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
      });

    if (uploadError) throw uploadError;

    const publicUrl = supabase.storage.from('stories').getPublicUrl(fileName).data.publicUrl;

    const { data: storyData, error: storyError } = await supabase
      .from('stories')
      .insert([{ user_id: userId, media_url: publicUrl, story_type: storyType }])
      .select();

    if (storyError) throw storyError;

    res.status(201).json(storyData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
