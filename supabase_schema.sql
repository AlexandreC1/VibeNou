-- VibeNou Database Schema for Supabase
-- Run this script in your Supabase SQL Editor

-- Enable PostGIS extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13),
  bio TEXT,
  interests TEXT[] DEFAULT '{}',
  photo_url TEXT,
  location GEOGRAPHY(POINT, 4326), -- PostGIS geography type for lat/lng
  city TEXT,
  country TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_active TIMESTAMPTZ DEFAULT NOW(),
  preferred_language TEXT DEFAULT 'en'
);

-- Index for geospatial queries (essential for performance)
CREATE INDEX IF NOT EXISTS users_location_idx ON users USING GIST(location);

-- Index for email lookups
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email);

-- Index for last active queries
CREATE INDEX IF NOT EXISTS users_last_active_idx ON users(last_active DESC);

-- Chat rooms table
CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_1 UUID REFERENCES users(id) ON DELETE CASCADE,
  participant_2 UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(participant_1, participant_2)
);

-- Index for finding user's chat rooms
CREATE INDEX IF NOT EXISTS chat_rooms_participant_1_idx ON chat_rooms(participant_1);
CREATE INDEX IF NOT EXISTS chat_rooms_participant_2_idx ON chat_rooms(participant_2);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

-- Index for chat queries (optimized for sorting by time)
CREATE INDEX IF NOT EXISTS messages_chat_room_idx ON messages(chat_room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS messages_sender_idx ON messages(sender_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users policies
-- Allow all authenticated users to view profiles (for discovery)
CREATE POLICY "Users can view all profiles"
  ON users FOR SELECT
  USING (auth.role() = 'authenticated');

-- Users can only insert their own profile during signup
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Users can only delete their own profile
CREATE POLICY "Users can delete own profile"
  ON users FOR DELETE
  USING (auth.uid() = id);

-- Chat room policies
-- Users can view chat rooms they're part of
CREATE POLICY "Users can view their own chats"
  ON chat_rooms FOR SELECT
  USING (
    auth.uid() = participant_1 OR
    auth.uid() = participant_2
  );

-- Users can create chat rooms where they are a participant
CREATE POLICY "Users can create chat rooms"
  ON chat_rooms FOR INSERT
  WITH CHECK (
    auth.uid() = participant_1 OR
    auth.uid() = participant_2
  );

-- Users can update chat rooms they're part of
CREATE POLICY "Users can update their chat rooms"
  ON chat_rooms FOR UPDATE
  USING (
    auth.uid() = participant_1 OR
    auth.uid() = participant_2
  );

-- Message policies
-- Users can view messages in their chat rooms
CREATE POLICY "Users can view messages in their chat rooms"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = messages.chat_room_id
      AND (
        chat_rooms.participant_1 = auth.uid() OR
        chat_rooms.participant_2 = auth.uid()
      )
    )
  );

-- Users can send messages (must be sender and part of the chat room)
CREATE POLICY "Users can send messages to their chat rooms"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = messages.chat_room_id
      AND (
        chat_rooms.participant_1 = auth.uid() OR
        chat_rooms.participant_2 = auth.uid()
      )
    )
  );

-- Users can update messages they sent (for read receipts, etc.)
CREATE POLICY "Users can update their own messages"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE chat_rooms.id = messages.chat_room_id
      AND (
        chat_rooms.participant_1 = auth.uid() OR
        chat_rooms.participant_2 = auth.uid()
      )
    )
  );

-- ============================================================================
-- DATABASE FUNCTIONS
-- ============================================================================

-- Function to get nearby users within a radius
CREATE OR REPLACE FUNCTION get_nearby_users(
  user_lat FLOAT,
  user_lng FLOAT,
  radius_km FLOAT DEFAULT 50,
  max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  interests TEXT[],
  photo_url TEXT,
  city TEXT,
  country TEXT,
  distance_km FLOAT,
  last_active TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.name,
    u.age,
    u.bio,
    u.interests,
    u.photo_url,
    u.city,
    u.country,
    ROUND(
      ST_Distance(
        u.location::geography,
        ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
      ) / 1000, 2
    ) AS distance_km,
    u.last_active
  FROM users u
  WHERE
    u.id != auth.uid()
    AND u.location IS NOT NULL
    AND ST_DWithin(
      u.location::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC
  LIMIT max_results;
END;
$$;

-- Function to get users with similar interests
CREATE OR REPLACE FUNCTION get_users_by_interests(
  user_interests TEXT[],
  max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  age INTEGER,
  bio TEXT,
  interests TEXT[],
  photo_url TEXT,
  city TEXT,
  country TEXT,
  common_interests INTEGER,
  last_active TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id,
    u.name,
    u.age,
    u.bio,
    u.interests,
    u.photo_url,
    u.city,
    u.country,
    (
      SELECT COUNT(*)::INTEGER
      FROM unnest(u.interests) interest
      WHERE interest = ANY(user_interests)
    ) AS common_interests,
    u.last_active
  FROM users u
  WHERE
    u.id != auth.uid()
    AND u.interests && user_interests  -- Array overlap operator
  ORDER BY common_interests DESC, u.last_active DESC
  LIMIT max_results;
END;
$$;

-- Function to get unread message count for a chat room
CREATE OR REPLACE FUNCTION get_unread_count(room_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER INTO unread_count
  FROM messages
  WHERE chat_room_id = room_id
    AND sender_id != auth.uid()
    AND read_at IS NULL;

  RETURN COALESCE(unread_count, 0);
END;
$$;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(room_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE messages
  SET read_at = NOW()
  WHERE chat_room_id = room_id
    AND sender_id != auth.uid()
    AND read_at IS NULL;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$;

-- Function to get or create a chat room between two users
CREATE OR REPLACE FUNCTION get_or_create_chat_room(other_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  room_id UUID;
  current_user_id UUID;
  p1 UUID;
  p2 UUID;
BEGIN
  current_user_id := auth.uid();

  -- Ensure consistent ordering (smaller UUID first)
  IF current_user_id < other_user_id THEN
    p1 := current_user_id;
    p2 := other_user_id;
  ELSE
    p1 := other_user_id;
    p2 := current_user_id;
  END IF;

  -- Try to find existing room
  SELECT id INTO room_id
  FROM chat_rooms
  WHERE (participant_1 = p1 AND participant_2 = p2)
     OR (participant_1 = p2 AND participant_2 = p1);

  -- Create if doesn't exist
  IF room_id IS NULL THEN
    INSERT INTO chat_rooms (participant_1, participant_2)
    VALUES (p1, p2)
    RETURNING id INTO room_id;
  END IF;

  RETURN room_id;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update chat_room updated_at when new message is sent
CREATE OR REPLACE FUNCTION update_chat_room_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE chat_rooms
  SET updated_at = NEW.created_at
  WHERE id = NEW.chat_room_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_update_chat_room_timestamp
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_timestamp();

-- Trigger to update user's last_active timestamp
CREATE OR REPLACE FUNCTION update_user_last_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE users
  SET last_active = NOW()
  WHERE id = NEW.sender_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_update_user_last_active
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_user_last_active();

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================
-- Note: Run these in the Supabase Dashboard > Storage section

-- Create a bucket for profile photos
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('profile-photos', 'profile-photos', true);

-- Storage policy for profile photos
-- CREATE POLICY "Users can upload their own profile photo"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--   bucket_id = 'profile-photos' AND
--   auth.uid()::text = (storage.foldername(name))[1]
-- );

-- CREATE POLICY "Profile photos are publicly accessible"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'profile-photos');

-- CREATE POLICY "Users can update their own profile photo"
-- ON storage.objects FOR UPDATE
-- USING (
--   bucket_id = 'profile-photos' AND
--   auth.uid()::text = (storage.foldername(name))[1]
-- );

-- CREATE POLICY "Users can delete their own profile photo"
-- ON storage.objects FOR DELETE
-- USING (
--   bucket_id = 'profile-photos' AND
--   auth.uid()::text = (storage.foldername(name))[1]
-- );

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Uncomment to insert sample data after creating test users via auth

-- INSERT INTO users (id, email, name, age, bio, interests, location, city, country)
-- VALUES
--   (
--     'your-test-user-uuid-1',
--     'test1@example.com',
--     'Jean Pierre',
--     28,
--     'Love Haitian music and culture',
--     ARRAY['music', 'culture', 'food'],
--     ST_SetSRID(ST_MakePoint(-72.3074, 18.5944), 4326)::geography, -- Port-au-Prince
--     'Port-au-Prince',
--     'Haiti'
--   );

-- ============================================================================
-- REALTIME SETUP
-- ============================================================================
-- Enable realtime for messages table
-- Go to Database > Replication and enable realtime for the 'messages' table

-- ============================================================================
-- INDEXES FOR OPTIMIZATION
-- ============================================================================

-- Create indexes for common query patterns
CREATE INDEX IF NOT EXISTS messages_unread_idx ON messages(chat_room_id, read_at)
WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS users_interests_idx ON users USING GIN(interests);

-- ============================================================================
-- COMPLETION
-- ============================================================================
-- Database schema setup complete!
-- Next steps:
-- 1. Create a storage bucket named 'profile-photos' in the Supabase dashboard
-- 2. Enable realtime for the 'messages' table
-- 3. Configure your Flutter app with Supabase URL and anon key
