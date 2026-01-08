-- SUPABASE STORAGE SETUP FOR MOVIE_ICONS BUCKET
-- ================================================
--
-- IMPORTANT: You need to set this up in your Supabase Dashboard since you don't have
-- admin privileges to run storage SQL directly.
--
-- STEP-BY-STEP INSTRUCTIONS:
--
-- 1. Go to your Supabase project dashboard
-- 2. Click on "Storage" in the left sidebar
-- 3. Click "Create bucket"
-- 4. Enter bucket name: "movie_icons" (exactly this name)
-- 5. ✅ Check "Public bucket" (important for profile images to be viewable)
-- 6. Click "Create bucket"
--
-- 7. After creating the bucket, click on the "movie_icons" bucket
-- 8. Go to the "Policies" tab
-- 9. Create the following 4 policies:
--
-- POLICY 1: Allow Authenticated Users to Upload
-- - Name: "Allow authenticated uploads"
-- - Allowed operations: INSERT
-- - Policy expression: auth.role() = 'authenticated'
--
-- POLICY 2: Allow Public Access to View
-- - Name: "Allow public access"
-- - Allowed operations: SELECT
-- - Policy expression: true
--
-- POLICY 3: Allow Authenticated Users to Update
-- - Name: "Allow authenticated updates"
-- - Allowed operations: UPDATE
-- - Policy expression: auth.role() = 'authenticated'
--
-- POLICY 4: Allow Authenticated Users to Delete
-- - Name: "Allow authenticated deletes"
-- - Allowed operations: DELETE
-- - Policy expression: auth.role() = 'authenticated'
--
-- Once you've created the bucket and policies in the dashboard,
-- the photo upload should work in your app!
--
-- ================================================
-- ALTERNATIVE: If you have admin access, you can run this SQL instead:

INSERT INTO storage.buckets (id, name, public)
VALUES ('movie_icons', 'movie_icons', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "movie_icons_insert" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'movie_icons' AND auth.role() = 'authenticated');

CREATE POLICY "movie_icons_select" ON storage.objects
FOR SELECT USING (bucket_id = 'movie_icons');

CREATE POLICY "movie_icons_update" ON storage.objects
FOR UPDATE USING (bucket_id = 'movie_icons' AND auth.role() = 'authenticated');

CREATE POLICY "movie_icons_delete" ON storage.objects
FOR DELETE USING (bucket_id = 'movie_icons' AND auth.role() = 'authenticated');