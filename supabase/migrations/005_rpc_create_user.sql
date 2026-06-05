-- ============================================================
-- College Portal - RPC to create auth users (super admin only)
-- Run this in Supabase SQL Editor after 004_seed_profiles.sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_auth_user(
  p_email text,
  p_password text,
  p_username text,
  p_full_name text,
  p_role text DEFAULT 'student',
  p_phone text DEFAULT '',
  p_is_prefect boolean DEFAULT false,
  p_is_super_admin boolean DEFAULT false
) RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_super_admin = true
  ) THEN
    RAISE EXCEPTION 'Only super admin can create users';
  END IF;

  v_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, confirmation_sent_at,
    confirmation_token, recovery_token,
    email_change, email_change_token_new, email_change_token_current,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at, phone,
    is_sso_user, is_anonymous
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id, 'authenticated', 'authenticated', p_email,
    crypt(p_password, gen_salt('bf')),
    now(), now(), '', '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object(
      'username', p_username,
      'full_name', p_full_name,
      'role', p_role,
      'phone', p_phone,
      'is_prefect', p_is_prefect,
      'is_super_admin', p_is_super_admin
    ),
    p_is_super_admin, now(), now(), p_phone,
    false, false
  );

  INSERT INTO auth.identities (
    id, user_id, identity_data, provider,
    provider_id, last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', p_email),
    'email', p_email, now(), now(), now()
  );

  INSERT INTO public.profiles (
    id, username, full_name, role, phone,
    is_super_admin, is_prefect, is_first_login, assigned_lessons
  ) VALUES (
    v_user_id, p_username, p_full_name, p_role, p_phone,
    p_is_super_admin, p_is_prefect, true, '{}'
  )
  ON CONFLICT (username) DO UPDATE SET
    id = EXCLUDED.id,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone,
    is_super_admin = EXCLUDED.is_super_admin,
    is_prefect = EXCLUDED.is_prefect,
    is_first_login = true;

  RETURN jsonb_build_object(
    'id', v_user_id,
    'email', p_email,
    'username', p_username,
    'full_name', p_full_name,
    'role', p_role
  );
END;
$$;
