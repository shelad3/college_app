-- Add missing RLS policies for lessons table (admin only write)
CREATE POLICY "lessons_insert_admin" ON public.lessons
  FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "lessons_update_admin" ON public.lessons
  FOR UPDATE USING (public.is_admin());

CREATE POLICY "lessons_delete_admin" ON public.lessons
  FOR DELETE USING (public.is_admin());
