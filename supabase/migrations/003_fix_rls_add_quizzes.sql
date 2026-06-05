-- ============================================================
-- Fix RLS recursion for profiles + add quizzes + seed auth
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. FIX RLS RECURSION for profiles
-- The old policy recursed: SELECT FROM profiles inside a profiles policy
CREATE OR REPLACE FUNCTION public.is_teacher_or_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND (role = 'teacher' OR is_super_admin = true)
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_super_admin = true
  );
$$;

DROP POLICY IF EXISTS "profiles_read_teachers" ON public.profiles;
CREATE POLICY "profiles_read_teachers" ON public.profiles
  FOR SELECT USING (public.is_teacher_or_admin());

-- Also need to fix the schedules/announcements/etc policies that use subqueries
DROP POLICY IF EXISTS "schedules_update_teacher" ON public.schedules;
DROP POLICY IF EXISTS "paragraphs_update_teacher" ON public.note_paragraphs;
DROP POLICY IF EXISTS "announcements_insert_teacher" ON public.announcements;

CREATE POLICY "schedules_update_teacher" ON public.schedules
  FOR UPDATE USING (public.is_teacher_or_admin());

CREATE POLICY "paragraphs_update_teacher" ON public.note_paragraphs
  FOR UPDATE USING (public.is_teacher_or_admin());

CREATE POLICY "announcements_insert_teacher" ON public.announcements
  FOR INSERT WITH CHECK (public.is_teacher_or_admin());

-- 2. DOCUMENTS TABLE (if not exists)
CREATE TABLE IF NOT EXISTS public.documents (
  id TEXT PRIMARY KEY,
  lesson_id BIGINT NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_url TEXT,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "documents_read_all" ON public.documents;
DROP POLICY IF EXISTS "documents_insert_teacher" ON public.documents;
DROP POLICY IF EXISTS "documents_delete_teacher" ON public.documents;

CREATE POLICY "documents_read_all" ON public.documents
  FOR SELECT USING (true);

CREATE POLICY "documents_insert_teacher" ON public.documents
  FOR INSERT WITH CHECK (public.is_teacher_or_admin());

CREATE POLICY "documents_delete_teacher" ON public.documents
  FOR DELETE USING (public.is_teacher_or_admin());

-- Add lesson_id to note_topics if not already present
ALTER TABLE public.note_topics ADD COLUMN IF NOT EXISTS lesson_id BIGINT REFERENCES public.lessons(id) ON DELETE CASCADE DEFAULT 1;

-- 3. QUIZZES
CREATE TABLE IF NOT EXISTS public.quizzes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id BIGINT NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  duration_minutes INT NOT NULL DEFAULT 10,
  due_date TIMESTAMPTZ,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "quizzes_read_all" ON public.quizzes
  FOR SELECT USING (true);

CREATE POLICY "quizzes_insert_teacher" ON public.quizzes
  FOR INSERT WITH CHECK (public.is_teacher_or_admin());

CREATE POLICY "quizzes_delete_teacher" ON public.quizzes
  FOR DELETE USING (public.is_teacher_or_admin());

CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  option_c TEXT NOT NULL,
  option_d TEXT NOT NULL,
  correct_answer TEXT NOT NULL CHECK (correct_answer IN ('a', 'b', 'c', 'd')),
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "questions_read_all" ON public.quiz_questions
  FOR SELECT USING (true);

CREATE POLICY "questions_insert_teacher" ON public.quiz_questions
  FOR INSERT WITH CHECK (public.is_teacher_or_admin());

CREATE POLICY "questions_delete_teacher" ON public.quiz_questions
  FOR DELETE USING (public.is_teacher_or_admin());

CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id UUID NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL DEFAULT 0,
  total_questions INT NOT NULL DEFAULT 0,
  answers JSONB NOT NULL DEFAULT '{}',
  started_at TIMESTAMPTZ DEFAULT now(),
  submitted_at TIMESTAMPTZ,
  UNIQUE(quiz_id, student_id)
);

ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attempts_select_own" ON public.quiz_attempts
  FOR SELECT USING (auth.uid() = student_id OR public.is_teacher_or_admin());

CREATE POLICY "attempts_insert_own" ON public.quiz_attempts
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "attempts_update_own" ON public.quiz_attempts
  FOR UPDATE USING (auth.uid() = student_id);

-- 4. SEED AUTH USERS (run after creating via UI or API)
-- These are created through the auth signup process.
-- Existing seeded users:
--   sheldonramu8@gmail.com / 0112327446  (super admin)
--   prefect@college.app / 0112327446      (class prefect)
--   teacher@college.app / 0712345678      (teacher)
--   student@college.app / 0712345678      (student)
