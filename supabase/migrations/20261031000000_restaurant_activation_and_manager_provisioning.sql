-- Migration: Restaurant Activation, Admin Restriction, and Automated Manager Provisioning
-- Description:
-- 1. Restricts restaurant status updates (including activation) to admin users only.
-- 2. Automatically generates a manager user with default credentials when an admin sets status = 'ACTIVE'.
-- 3. Stores manager credentials in restaurants.owners_details under 'manager_credentials' for owner access.
-- 4. Provides manager password update facilities (RPC, trigger sync on auth.users, and Edge Function).
-- 5. Configures RLS policies for Admins, Owners, and Managers.

-- 1. Trigger function: Enforce admin-only permission for updating restaurant status
CREATE OR REPLACE FUNCTION public.enforce_restaurant_admin_activation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_jwt_role text;
  v_app_role text;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    v_jwt_role := auth.role();
    
    -- If called by authenticated user (via PostgREST/client SDK)
    IF v_jwt_role = 'authenticated' THEN
      v_app_role := (auth.jwt() -> 'app_metadata'::text) ->> 'role'::text;
      IF v_app_role IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Permission denied: Only administrators are authorized to activate or change restaurant status';
      END IF;
    ELSIF v_jwt_role IS NOT NULL AND v_jwt_role <> 'service_role' THEN
      RAISE EXCEPTION 'Permission denied: Only administrators are authorized to activate or change restaurant status';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- 2. Trigger function: Auto-generate manager user on restaurant activation
CREATE OR REPLACE FUNCTION public.handle_restaurant_activation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_manager_id uuid;
  v_manager_email text;
  v_default_password text;
  v_clean_name text;
BEGIN
  -- Trigger when status transitions to 'ACTIVE' from another status
  IF (OLD.status IS DISTINCT FROM 'ACTIVE' AND NEW.status = 'ACTIVE') THEN
    
    -- Idempotency check: Skip if manager credentials already exist
    IF NEW.owners_details IS NOT NULL AND NEW.owners_details ? 'manager_credentials' THEN
      RETURN NEW;
    END IF;

    -- Generate manager UUID
    v_manager_id := gen_random_uuid();

    -- Generate slug for manager email
    v_clean_name := lower(regexp_replace(COALESCE(NEW.restaurant_id, NEW.name), '[^a-zA-Z0-9]', '', 'g'));
    IF length(v_clean_name) = 0 THEN
      v_clean_name := 'restaurant';
    END IF;

    v_manager_email := 'manager.' || v_clean_name || '@booknbytes.app';

    -- Ensure unique email
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_manager_email) THEN
      v_manager_email := 'manager.' || v_clean_name || '.' || substring(replace(gen_random_uuid()::text, '-', '') from 1 for 4) || '@booknbytes.app';
    END IF;

    -- Generate secure default password (e.g. Mgr@a1b2c3d4!)
    v_default_password := 'Mgr@' || substring(replace(gen_random_uuid()::text, '-', '') from 1 for 8) || '!';

    -- Insert into auth.users (with empty string tokens for GoTrue Go scanner compatibility)
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      email_change_token_current,
      phone_change,
      phone_change_token,
      reauthentication_token,
      is_sso_user,
      is_anonymous
    ) VALUES (
      '00000000-0000-0000-0000-000000000000'::uuid,
      v_manager_id,
      'authenticated',
      'authenticated',
      v_manager_email,
      extensions.crypt(v_default_password, extensions.gen_salt('bf')),
      now(),
      jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email'),
        'role', 'restaurant_manager',
        'restaurant_id', NEW.restaurant_id
      ),
      jsonb_build_object(
        'name', 'Manager - ' || COALESCE(NEW.name, 'Restaurant'),
        'restaurant_id', NEW.restaurant_id
      ),
      now(),
      now(),
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      false,
      false
    );

    -- Insert into auth.identities
    INSERT INTO auth.identities (
      id,
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_manager_id::text,
      v_manager_id,
      jsonb_build_object(
        'sub', v_manager_id::text,
        'email', v_manager_email,
        'email_verified', true
      ),
      'email',
      now(),
      now(),
      now()
    );

    -- Attach manager_credentials to NEW.owners_details
    NEW.owners_details := COALESCE(NEW.owners_details, '{}'::jsonb) || jsonb_build_object(
      'manager_credentials', jsonb_build_object(
        'manager_id', v_manager_id,
        'email', v_manager_email,
        'default_password', v_default_password,
        'created_at', now(),
        'password_updated', false
      )
    );

  END IF;

  RETURN NEW;
END;
$$;

-- 3. Triggers on public.restaurants
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_enforce_admin_activation'
  ) THEN
    CREATE TRIGGER trg_enforce_admin_activation
    BEFORE UPDATE OF status ON public.restaurants
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_restaurant_admin_activation();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_handle_restaurant_activation'
  ) THEN
    CREATE TRIGGER trg_handle_restaurant_activation
    BEFORE UPDATE OF status ON public.restaurants
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_restaurant_activation();
  END IF;
END $$;

-- 4. RPC function: Allow authenticated manager to update their password
CREATE OR REPLACE FUNCTION public.update_manager_password(new_password text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_user_id uuid;
  v_role text;
  v_restaurant_id text;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF length(new_password) < 8 THEN
    RAISE EXCEPTION 'Password must be at least 8 characters long';
  END IF;

  v_role := (auth.jwt() -> 'app_metadata'::text) ->> 'role'::text;
  v_restaurant_id := (auth.jwt() -> 'app_metadata'::text) ->> 'restaurant_id'::text;

  -- 1. Update encrypted_password in auth.users
  UPDATE auth.users
  SET encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
      updated_at = now()
  WHERE id = v_user_id;

  -- 2. If user is a restaurant_manager, update the flag and mask default_password in public.restaurants
  IF v_role = 'restaurant_manager' AND v_restaurant_id IS NOT NULL THEN
    UPDATE public.restaurants
    SET owners_details = jsonb_set(
      jsonb_set(COALESCE(owners_details, '{}'::jsonb), '{manager_credentials,password_updated}', 'true'::jsonb),
      '{manager_credentials,default_password}',
      '"[PASSWORD_UPDATED]"'::jsonb
    )
    WHERE restaurant_id = v_restaurant_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Password updated successfully'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_manager_password(text) TO authenticated;

-- 5. Trigger to synchronize manager password updates from native auth (supabase.auth.updateUser)
CREATE OR REPLACE FUNCTION public.sync_manager_password_updated()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_role text;
  v_restaurant_id text;
BEGIN
  IF NEW.encrypted_password IS DISTINCT FROM OLD.encrypted_password THEN
    v_role := NEW.raw_app_meta_data->>'role';
    v_restaurant_id := NEW.raw_app_meta_data->>'restaurant_id';

    IF v_role = 'restaurant_manager' AND v_restaurant_id IS NOT NULL THEN
      UPDATE public.restaurants
      SET owners_details = jsonb_set(
        jsonb_set(COALESCE(owners_details, '{}'::jsonb), '{manager_credentials,password_updated}', 'true'::jsonb),
        '{manager_credentials,default_password}',
        '"[PASSWORD_UPDATED]"'::jsonb
      )
      WHERE restaurant_id = v_restaurant_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_sync_manager_password_updated'
  ) THEN
    CREATE TRIGGER trg_sync_manager_password_updated
    AFTER UPDATE OF encrypted_password ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_manager_password_updated();
  END IF;
END $$;

-- 6. RLS Policies on public.restaurants
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'restaurants' AND policyname = 'Admins have full access to restaurants'
  ) THEN
    CREATE POLICY "Admins have full access to restaurants"
    ON public.restaurants
    FOR ALL
    TO authenticated
    USING (((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'admin')
    WITH CHECK (((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'admin');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'restaurants' AND policyname = 'Owners and managers view their restaurant'
  ) THEN
    CREATE POLICY "Owners and managers view their restaurant"
    ON public.restaurants
    FOR SELECT
    TO authenticated
    USING (
      (((auth.jwt() -> 'app_metadata'::text) ->> 'restaurant_id'::text) = restaurant_id)
      OR ((owners_details->>'owner_id') = auth.uid()::text)
    );
  END IF;
END $$;
