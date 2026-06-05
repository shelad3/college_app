-- ============================================================
-- Documents Table
-- Run this in Supabase SQL Editor
-- ============================================================

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

CREATE POLICY "documents_read_all" ON public.documents
  FOR SELECT USING (true);

CREATE POLICY "documents_insert_teacher" ON public.documents
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'teacher' OR is_super_admin = true OR is_prefect = true))
  );

CREATE POLICY "documents_delete_teacher" ON public.documents
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND (role = 'teacher' OR is_super_admin = true))
  );

-- Add lesson_id to note_topics if not already present
ALTER TABLE public.note_topics ADD COLUMN IF NOT EXISTS lesson_id BIGINT REFERENCES public.lessons(id) ON DELETE CASCADE DEFAULT 1;

-- ============================================================
-- Storage bucket for documents
-- Run in Supabase Dashboard > Storage > Create bucket
-- Name: documents
-- Public bucket: false
-- ============================================================
-- After creating the bucket, run:
--
-- CREATE POLICY "documents_upload" ON storage.objects
--   FOR INSERT WITH CHECK (
--     bucket_id = 'documents' AND
--     auth.role() = 'authenticated'
--   );
--
-- CREATE POLICY "documents_read" ON storage.objects
--   FOR SELECT USING (bucket_id = 'documents');
