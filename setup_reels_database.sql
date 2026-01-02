-- ============================================
-- REELS DATABASE SETUP FOR SUPABASE
-- ============================================

-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/YOUR_PROJECT/database/sql

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS public.reel_likes CASCADE;
DROP TABLE IF EXISTS public.reels CASCADE;

-- Create reels table
CREATE TABLE public.reels (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  video_url TEXT NOT NULL,
  caption TEXT,
  music TEXT,
  likes_count INTEGER DEFAULT 0 NOT NULL,
  comments_count INTEGER DEFAULT 0 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;

-- Create policies for reels
CREATE POLICY "Public reels are viewable by everyone"
ON public.reels FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own reels"
ON public.reels FOR INSERT
WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can update their own reels"
ON public.reels FOR UPDATE
WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can delete their own reels"
ON public.reels FOR DELETE
USING (auth.role() = 'authenticated' AND auth.uid() = user_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage reels"
ON public.reels FOR ALL
USING (auth.role() = 'service_role');

-- Create indexes
CREATE INDEX IF NOT EXISTS reels_user_id_idx ON public.reels (user_id);
CREATE INDEX IF NOT EXISTS reels_created_at_idx ON public.reels (created_at);

-- Create reel_likes table
CREATE TABLE public.reel_likes (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reel_id UUID REFERENCES public.reels(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(reel_id, user_id)
);

-- Enable RLS
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;

-- Create policies for reel_likes
CREATE POLICY "Users can insert their own reel likes"
ON public.reel_likes FOR INSERT
WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Users can delete their own reel likes"
ON public.reel_likes FOR DELETE
USING (auth.role() = 'authenticated' AND auth.uid() = user_id);

-- Users can view all reel likes (for counting)
CREATE POLICY "Reel likes are viewable by everyone"
ON public.reel_likes FOR SELECT
USING (true);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage reel likes"
ON public.reel_likes FOR ALL
USING (auth.role() = 'service_role');

-- Create indexes
CREATE INDEX IF NOT EXISTS reel_likes_reel_id_idx ON public.reel_likes (reel_id);
CREATE INDEX IF NOT EXISTS reel_likes_user_id_idx ON public.reel_likes (user_id);

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- Create RPC function to increment reel likes count
CREATE OR REPLACE FUNCTION increment_reel_likes_count(reel_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.reels 
  SET likes_count = likes_count + 1,
      updated_at = now()
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC function to decrement reel likes count
CREATE OR REPLACE FUNCTION decrement_reel_likes_count(reel_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.reels 
  SET likes_count = GREATEST(likes_count - 1, 0),
      updated_at = now()
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC function to increment reel comments count
CREATE OR REPLACE FUNCTION increment_reel_comments_count(reel_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.reels 
  SET comments_count = comments_count + 1,
      updated_at = now()
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC function to decrement reel comments count
CREATE OR REPLACE FUNCTION decrement_reel_comments_count(reel_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.reels 
  SET comments_count = GREATEST(comments_count - 1, 0),
      updated_at = now()
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_reel_likes_count(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION decrement_reel_likes_count(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION increment_reel_comments_count(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION decrement_reel_comments_count(UUID) TO authenticated, service_role;

-- ============================================
-- STORAGE POLICIES FOR REELS
-- ============================================

-- Drop existing policies for reels bucket
DROP POLICY IF EXISTS "Reels are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload reels" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own reels" ON storage.objects;
DROP POLICY IF EXISTS "Service role can manage reels" ON storage.objects;

-- Create new storage policies for reels bucket
CREATE POLICY "Reels are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'reels');

CREATE POLICY "Authenticated users can upload reels"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'reels' AND (auth.role() = 'authenticated' OR auth.role() = 'service_role'));

CREATE POLICY "Users can delete own reels"
ON storage.objects FOR DELETE
USING (bucket_id = 'reels' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Service role can manage reels"
ON storage.objects FOR ALL
USING (bucket_id = 'reels' AND auth.role() = 'service_role');

-- ============================================
-- SETUP COMPLETE!
-- ============================================

SELECT 'Reels database setup complete!' as status;