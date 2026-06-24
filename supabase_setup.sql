-- ============================================================
-- SUPABASE SETUP SCRIPT FOR RTC CHECKING APP
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. DROP existing table (if exists) to start fresh
DROP TABLE IF EXISTS locations CASCADE;

-- 2. CREATE locations table
CREATE TABLE locations (
  id TEXT PRIMARY KEY,
  title TEXT DEFAULT 'Vị trí',
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  radius DOUBLE PRECISION DEFAULT 25,
  notification_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- 4. Create policies for public access (no auth required)
-- Allow anyone to read locations
CREATE POLICY "Allow public read" ON locations
  FOR SELECT USING (true);

-- Allow anyone to insert locations
CREATE POLICY "Allow public insert" ON locations
  FOR INSERT WITH CHECK (true);

-- Allow anyone to update locations
CREATE POLICY "Allow public update" ON locations
  FOR UPDATE USING (true);

-- Allow anyone to delete locations
CREATE POLICY "Allow public delete" ON locations
  FOR DELETE USING (true);

-- 5. Verify the table was created correctly
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'locations' 
ORDER BY ordinal_position;

-- 6. Test insert (this should work after running this script)
-- INSERT INTO locations (id, title, lat, lng, radius, notification_enabled)
-- VALUES ('test-123', 'Test Location', 21.047450, 105.735178, 25, true);

-- 7. Check if RLS is enabled
-- SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'locations';

-- 8. List all policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename = 'locations';
