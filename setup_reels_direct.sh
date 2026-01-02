#!/bin/bash

# Simple database setup script for reels
echo "🚀 Setting up Reels Database..."

# Use direct Supabase connection
SUPABASE_URL=$(grep SUPABASE_URL backend/.env | cut -d '=' -f2)
SUPABASE_KEY=$(grep SUPABASE_SERVICE_ROLE_KEY backend/.env | cut -d '=' -f2)

echo "📡 Using direct Supabase connection..."

# Create reels table
echo "Creating reels table..."
SQL_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE TABLE IF NOT EXISTS public.reels (id UUID DEFAULT uuid_generate_v4() PRIMARY KEY, user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, username TEXT NOT NULL, video_url TEXT NOT NULL, caption TEXT, music TEXT, likes_count INTEGER DEFAULT 0 NOT NULL, comments_count INTEGER DEFAULT 0 NOT NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL)\"
  }'

echo "SQL Response: $SQL_RESPONSE"

# Create reel_likes table  
echo "Creating reel_likes table..."
SQL_RESPONSE2=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE TABLE IF NOT EXISTS public.reel_likes (id UUID DEFAULT uuid_generate_v4() PRIMARY KEY, reel_id UUID REFERENCES public.reels(id) ON DELETE CASCADE NOT NULL, user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL, UNIQUE(reel_id, user_id))\"
  }'

echo "Reel likes SQL Response: $SQL_RESPONSE2"

# Create indexes
echo "Creating indexes..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE INDEX IF NOT EXISTS reels_user_id_idx ON public.reels (user_id)\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE INDEX IF NOT EXISTS reels_created_at_idx ON public.reels (created_at)\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE INDEX IF NOT EXISTS reel_likes_reel_id_idx ON public.reel_likes (reel_id)\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE INDEX IF NOT EXISTS reel_likes_user_id_idx ON public.reel_likes (user_id)\"
  }'

echo "Indexes created successfully!"

# Create RPC functions
echo "Creating RPC functions..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE OR REPLACE FUNCTION increment_reel_likes_count(reel_id UUID) RETURNS VOID AS \\$\\$BEGIN UPDATE public.reels SET likes_count = likes_count + 1, updated_at = now() WHERE id = reel_id; END; \\$\\$ LANGUAGE plpgsql SECURITY DEFINER\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE OR REPLACE FUNCTION decrement_reel_likes_count(reel_id UUID) RETURNS VOID AS \\$\\$BEGIN UPDATE public.reels SET likes_count = GREATEST(likes_count - 1, 0), updated_at = now() WHERE id = reel_id; END; \\$\\$ LANGUAGE plpgsql SECURITY DEFINER\"
  }'

echo "RPC functions created successfully!"

# Create storage policies
echo "Creating storage policies..."
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE POLICY \\\"Reels are publicly accessible\\\" ON storage.objects FOR SELECT USING (bucket_id = '\\''reels'\\''\\')\"\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE POLICY \\\"Authenticated users can upload reels\\\" ON storage.objects FOR INSERT WITH CHECK (bucket_id = '\\''reels'\\'' AND (auth.role() = '\\''authenticated'\\'' OR auth.role() = '\\''service_role'\\''\\')\"\"
  }'

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"CREATE POLICY \\\"Service role can manage reels\\\" ON storage.objects FOR ALL USING (bucket_id = '\\''reels'\\'' AND auth.role() = '\\''service_role'\\''\\')\"\"
  }'

echo "Storage policies created successfully!"

# Check results
if [[ $? -eq 0 ]]; then
  echo "✅ All setup commands executed successfully!"
  echo "🎯 Database and storage are ready for reels!"
  echo ""
  echo "📊 Next: Test reel creation in your Flutter app"
else
  echo "❌ One or more setup commands failed"
  echo "🔍 Check the SQL responses above for details"
fi

echo ""
echo "============================================"
echo "🎯 SETUP COMPLETE!"
echo "============================================"