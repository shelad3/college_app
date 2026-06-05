-- ============================================================
-- College Portal - Fix missing RLS policies
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. ANNOUNCEMENTS — missing SELECT policy (blocks initSupabaseData)
DROP POLICY IF EXISTS "announcements_read_all" ON public.announcements;
CREATE POLICY "announcements_read_all" ON public.announcements
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "announcements_delete_teacher" ON public.announcements;
CREATE POLICY "announcements_delete_teacher" ON public.announcements
  FOR DELETE USING (public.is_admin());

-- 2. SCHEDULES — missing INSERT/DELETE for admin
DROP POLICY IF EXISTS "schedules_insert_admin" ON public.schedules;
DROP POLICY IF EXISTS "schedules_delete_admin" ON public.schedules;

CREATE POLICY "schedules_insert_admin" ON public.schedules
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "schedules_delete_admin" ON public.schedules
  FOR DELETE USING (public.is_admin());

-- 3. NOTE TOPICS — missing INSERT/DELETE for admin
DROP POLICY IF EXISTS "topics_insert_admin" ON public.note_topics;
DROP POLICY IF EXISTS "topics_delete_admin" ON public.note_topics;

CREATE POLICY "topics_insert_admin" ON public.note_topics
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "topics_delete_admin" ON public.note_topics
  FOR DELETE USING (public.is_admin());

-- 4. NOTE PARAGRAPHS — missing INSERT/DELETE for admin
DROP POLICY IF EXISTS "paragraphs_insert_admin" ON public.note_paragraphs;
DROP POLICY IF EXISTS "paragraphs_delete_admin" ON public.note_paragraphs;

CREATE POLICY "paragraphs_insert_admin" ON public.note_paragraphs
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "paragraphs_delete_admin" ON public.note_paragraphs
  FOR DELETE USING (public.is_admin());

-- 5. DISCUSSIONS — missing DELETE for admin
DROP POLICY IF EXISTS "discussions_delete_admin" ON public.discussions;
CREATE POLICY "discussions_delete_admin" ON public.discussions
  FOR DELETE USING (public.is_admin());
