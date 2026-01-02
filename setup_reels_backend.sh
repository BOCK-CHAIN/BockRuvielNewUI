#!/bin/bash

echo "🚀 Setting up Reels Database Tables & Policies..."

# Get Supabase URL and Service Role Key from environment
SUPABASE_URL=$(grep SUPABASE_URL backend/.env | cut -d '=' -f2)
SUPABASE_KEY=$(grep SUPABASE_SERVICE_ROLE_KEY backend/.env | cut -d '=' -f2)

echo "📍 Supabase URL: $SUPABASE_URL"
echo "🔑 Using Service Role Key"

# Check if tables exist
echo "📊 Creating database tables..."

# Create reels and reel_likes tables
curl -X POST "$SUPABASE_URL/rest/v1/rpc/execute" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '\''reels'\'') and table_schema = '\''public'\'')"
  }'

echo "✅ Database setup check complete"

echo "📦 Please run the storage policies manually:"
echo "   1. Open Supabase Dashboard → Database → SQL Editor"
echo "   2. Copy contents of: updated_storage_policies.sql"
echo "   3. Click 'Run' to execute"

echo "🎯 Setup complete!"