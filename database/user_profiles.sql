-- User profiles table for additional user information
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  profile_icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, profile_icon)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'username', 
    (ARRAY['https://mmueapwicxmuywaxugtj.supabase.co/storage/v1/object/public/movie_icons/icon1.png',
           'https://mmueapwicxmuywaxugtj.supabase.co/storage/v1/object/public/movie_icons/icon2.png',
           'https://mmueapwicxmuywaxugtj.supabase.co/storage/v1/object/public/movie_icons/icon3.png',
           'https://mmueapwicxmuywaxugtj.supabase.co/storage/v1/object/public/movie_icons/icon4.png',
           'https://mmueapwicxmuywaxugtj.supabase.co/storage/v1/object/public/movie_icons/icon5.png'])[floor(random() * 5 + 1)::int]);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create profile on user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();