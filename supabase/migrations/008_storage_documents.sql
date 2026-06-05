-- Storage bucket for document uploads
-- Run these after creating the bucket in Supabase Dashboard > Storage:
-- Name: documents
-- Public bucket: false

-- Bucket creation via SQL (requires storage extension)
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES ('documents', 'documents', false, false, 52428800, NULL)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage.objects
CREATE POLICY "documents_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'documents' AND auth.role() = 'authenticated'
  );

CREATE POLICY "documents_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "documents_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'documents' AND public.is_admin()
  );
