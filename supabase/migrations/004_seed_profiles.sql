-- ============================================================
-- Fix seed profiles with correct flags
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- Fix prefect flags
UPDATE public.profiles
SET is_prefect = true
WHERE username IN ('PREFECT/001', 'PREFECT/002');

-- Fix teacher role
UPDATE public.profiles
SET role = 'teacher'
WHERE username ~ '^\d+$';

-- Assign lessons to teacher
UPDATE public.profiles
SET assigned_lessons = '{1,2,3,4}'
WHERE role = 'teacher';

-- Set super admin if needed
UPDATE public.profiles
SET is_super_admin = true,
    role = 'student',
    full_name = 'Sheldon Ramu',
    phone = '0112327446'
WHERE username = 'EIT/500/S25/038';

-- Verify all users
SELECT username, full_name, role, is_super_admin, is_prefect, phone
FROM public.profiles
ORDER BY role, username;
