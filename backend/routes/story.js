
import express from 'express';
import multer from 'multer';
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const router = express.Router();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);
const storage = multer.memoryStorage();
const upload = multer({ storage });

const storyExpiry = 24 * 60 * 60 * 1000; // 24 hours

// POST /api/stories/upload
router.post('/stories/upload', upload.single('media'), async (req, res) => {
  const { userId, isVideo } = req.body;
  const mediaFile = req.file;

  try {
    const extension = isVideo === 'true' ? 'mp4' : 'jpg';
    const fileName = `story_${Date.now()}_${userId}.${extension}`;
    const storagePath = `${userId}/${fileName}`;
    const bucket = 'stories';

    const { error } = await supabase.storage
      .from(bucket)
      .upload(storagePath, mediaFile.buffer, {
        contentType: mediaFile.mimetype,
        upsert: true,
      });

    if (error) {
      throw error;
    }

    const { data } = supabase.storage.from(bucket).getPublicUrl(storagePath);

    res.json({ url: data.publicUrl });
  } catch (error) {
    res.status(500).json({ error: 'Story media upload failed' });
  }
});

// POST /api/stories
router.post('/stories', async (req, res) => {
  const { userId, imageUrl, videoUrl, caption } = req.body;

  try {
    const expiresAt = new Date(Date.now() + storyExpiry).toISOString();

    const { data, error } = await supabase
      .from('stories')
      .insert([
        {
          user_id: userId,
          image_url: imageUrl,
          video_url: videoUrl,
          caption,
          expires_at: expiresAt,
        },
      ])
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: 'Error creating story' });
  }
});

// GET /api/stories/following/:userId
router.get('/stories/following/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const { data: following, error: followingError } = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', userId);

    if (followingError) {
      throw followingError;
    }

    const followingIds = following.map((f) => f.following_id);
    followingIds.push(userId);

    const now = new Date().toISOString();
    const { data, error } = await supabase
      .from('stories')
      .select('*, profiles!stories_user_id_fkey(username, profile_image_url)')
      .in('user_id', followingIds)
      .gte('expires_at', now)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    const grouped = {};
    for (const story of data) {
      if (!grouped[story.user_id]) {
        grouped[story.user_id] = [];
      }
      grouped[story.user_id].push(story);
    }

    res.json(grouped);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching stories' });
  }
});

// GET /api/stories/user/:userId
router.get('/stories/user/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const now = new Date().toISOString();
    const { data, error } = await supabase
      .from('stories')
      .select('*, profiles!stories_user_id_fkey(username, profile_image_url)')
      .eq('user_id', userId)
      .gte('expires_at', now)
      .order('created_at', { ascending: false });

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching user stories' });
  }
});

export default router;
