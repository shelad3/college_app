-- ============================================================
-- College Portal - Initial Schema Migration
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- 1. PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'teacher')),
  phone TEXT,
  is_first_login BOOLEAN DEFAULT true,
  assigned_lessons INT[] DEFAULT '{}',
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. LESSONS
CREATE TABLE IF NOT EXISTS public.lessons (
  id BIGINT PRIMARY KEY,
  subject_name TEXT NOT NULL,
  instructor TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

-- 3. SCHEDULES
CREATE TABLE IF NOT EXISTS public.schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id BIGINT NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  day TEXT NOT NULL,
  time TEXT NOT NULL,
  room TEXT NOT NULL,
  is_shifted BOOLEAN DEFAULT false,
  shifted_time TEXT,
  shifted_room TEXT,
  shifted_date TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;

-- 4. NOTE TOPICS
CREATE TABLE IF NOT EXISTS public.note_topics (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.note_topics ENABLE ROW LEVEL SECURITY;

-- 5. NOTE PARAGRAPHS
CREATE TABLE IF NOT EXISTS public.note_paragraphs (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL REFERENCES public.note_topics(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  taught_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.note_paragraphs ENABLE ROW LEVEL SECURITY;

-- 6. STUDENT NOTES (personal notebook entries)
CREATE TABLE IF NOT EXISTS public.student_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paragraph_id TEXT NOT NULL REFERENCES public.note_paragraphs(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  note TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(paragraph_id, student_id)
);

ALTER TABLE public.student_notes ENABLE ROW LEVEL SECURITY;

-- 7. ANNOUNCEMENTS
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- 8. DISCUSSIONS (chat messages)
CREATE TABLE IF NOT EXISTS public.discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_name TEXT NOT NULL,
  user_id UUID REFERENCES public.profiles(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.discussions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- PROFILES
CREATE POLICY "profiles_read_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_read_teachers" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
  );
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- LESSONS
CREATE POLICY "lessons_read_all" ON public.lessons
  FOR SELECT USING (true);

-- SCHEDULES
CREATE POLICY "schedules_read_all" ON public.schedules
  FOR SELECT USING (true);
CREATE POLICY "schedules_update_teacher" ON public.schedules
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
  );

-- NOTE TOPICS
CREATE POLICY "topics_read_all" ON public.note_topics
  FOR SELECT USING (true);

-- NOTE PARAGRAPHS
CREATE POLICY "paragraphs_read_all" ON public.note_paragraphs
  FOR SELECT USING (true);
CREATE POLICY "paragraphs_update_teacher" ON public.note_paragraphs
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
  );

-- STUDENT NOTES
CREATE POLICY "student_notes_select_own" ON public.student_notes
  FOR SELECT USING (auth.uid() = student_id);
CREATE POLICY "student_notes_insert_own" ON public.student_notes
  FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "student_notes_update_own" ON public.student_notes
  FOR UPDATE USING (auth.uid() = student_id);

-- ANNOUNCEMENTS
CREATE POLICY "announcements_read_all" ON public.announcements
  FOR SELECT USING (true);
CREATE POLICY "announcements_insert_teacher" ON public.announcements
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
  );

-- DISCUSSIONS
CREATE POLICY "discussions_read_all" ON public.discussions
  FOR SELECT USING (true);
CREATE POLICY "discussions_insert_all" ON public.discussions
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- TRIGGER: Auto-create profile on signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, role, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- SEED DATA
-- ============================================================

INSERT INTO public.lessons (id, subject_name, instructor) VALUES
  (1, 'Electrical Principles & Circuits', 'Instructor A'),
  (2, 'Electronics & Telecommunications', 'Instructor B'),
  (3, 'Computer Logic & Microprocessors', 'Instructor C'),
  (4, 'Practical Systems & Labs', 'Instructor D')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.schedules (lesson_id, day, time, room) VALUES
  (1, 'Monday', '08:00 - 10:00', 'Lab 101'),
  (1, 'Wednesday', '10:00 - 12:00', 'Room 203'),
  (2, 'Tuesday', '09:00 - 11:00', 'Lab 102'),
  (2, 'Thursday', '14:00 - 16:00', 'Room 205'),
  (3, 'Monday', '13:00 - 15:00', 'Lab 103'),
  (3, 'Wednesday', '08:00 - 10:00', 'Room 207'),
  (4, 'Friday', '08:00 - 12:00', 'Main Lab'),
  (4, 'Tuesday', '13:00 - 15:00', 'Room 209')
ON CONFLICT DO NOTHING;

INSERT INTO public.note_topics (id, title) VALUES
  ('t1', 'Topic 1: Practical Verification'),
  ('t2', 'Topic 2: System Architecture Code')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.note_paragraphs (id, topic_id, text) VALUES
  ('p1', 't1', 'Verification is the process of confirming that a system meets its specified requirements. In practical engineering, this involves systematic testing and measurement of circuit behavior against theoretical predictions.'),
  ('p2', 't1', 'The verification methodology includes both simulation-based approaches and physical measurements using oscilloscopes, multimeters, and signal analyzers.'),
  ('p3', 't1', 'Key verification metrics include signal integrity, power consumption, timing analysis, and thermal characteristics under normal and stress conditions.'),
  ('p4', 't2', 'System architecture defines the fundamental organization of a system, embodied in its components, their relationships to each other and to the environment, and the principles guiding its design and evolution.'),
  ('p5', 't2', 'Modern embedded systems architecture follows a layered approach: hardware abstraction layer, operating system layer, application framework, and user interface.'),
  ('p6', 't2', 'Code architecture patterns such as MVC, MVVM, and clean architecture help maintain separation of concerns and testability in complex systems.')
ON CONFLICT (id) DO NOTHING;
