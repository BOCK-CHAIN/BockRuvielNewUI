-- ============================================
-- UPDATED STORAGE POLICIES FOR SUPABASE
-- ============================================

-- Drop existing policies for profiles bucket
DROP POLICY IF EXISTS "Profiles are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload profiles" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile picture" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile picture" ON storage.objects;
DROP POLICY IF EXISTS "Service role can manage profiles" ON storage.objects;

-- Create new storage policies for profiles bucket
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

CREATE POLICY "Service role can manage profiles"
ON storage.objects FOR ALL
USING (bucket_id = 'profiles' AND auth.role() = 'service_role');

-- ============================================
-- POLICIES SETUP COMPLETE!
-- ============================================

SELECT 'Storage policies updated!' as status;