-- ============================================
-- UPDATED STORAGE POLICIES FOR SUPABASE
-- ============================================

-- ============================================
-- POSTS BUCKET POLICIES
-- ============================================
CREATE POLICY "Posts are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'posts');

CREATE POLICY "Authenticated users can upload posts"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'posts' AND (auth.role() = 'authenticated' OR auth.role() = 'service_role'));

CREATE POLICY "Users can update own posts"
ON storage.objects FOR UPDATE
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own posts"
ON storage.objects FOR DELETE
USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage posts"
ON storage.objects FOR ALL
USING (bucket_id = 'posts' AND auth.role() = 'service_role');

-- ============================================
-- STORIES BUCKET POLICIES
-- ============================================
CREATE POLICY "Stories are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'stories');

CREATE POLICY "Authenticated users can upload stories"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'stories' AND (auth.role() = 'authenticated' OR auth.role() = 'service_role'));

CREATE POLICY "Users can delete own stories"
ON storage.objects FOR DELETE
USING (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage stories"
ON storage.objects FOR ALL
USING (bucket_id = 'stories' AND auth.role() = 'service_role');

-- ============================================
-- REELS BUCKET POLICIES
-- ============================================
CREATE POLICY "Reels are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'reels');

CREATE POLICY "Authenticated users can upload reels"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'reels' AND (auth.role() = 'authenticated' OR auth.role() = 'service_role'));

CREATE POLICY "Users can delete own reels"
ON storage.objects FOR DELETE
USING (bucket_id = 'reels' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage reels"
ON storage.objects FOR ALL
USING (bucket_id = 'reels' AND auth.role() = 'service_role');

-- ============================================
-- PROFILES BUCKET POLICIES
-- ============================================
CREATE POLICY "Profiles are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profiles');

CREATE POLICY "Authenticated users can upload profiles"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'profiles' AND (auth.role() = 'authenticated' OR auth.role() = 'service_role'));

CREATE POLICY "Users can update own profile picture"
ON storage.objects FOR UPDATE
USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own profile picture"
ON storage.objects FOR DELETE
USING (bucket_id = 'profiles' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Service role bypass for backend operations
CREATE POLICY "Service role can manage profiles"
ON storage.objects FOR ALL
USING (bucket_id = 'profiles' AND auth.role() = 'service_role');

-- ============================================
-- POLICIES SETUP COMPLETE!
-- ============================================