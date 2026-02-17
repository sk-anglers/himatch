-- ============================================================
-- Fix: Remove overly permissive invite code policy (USING(true))
-- Replace with SECURITY DEFINER function for invite code lookup
-- ============================================================

-- Drop the overly permissive policy that exposes all groups
DROP POLICY IF EXISTS "Anyone can read group by invite code" ON groups;

-- Create a SECURITY DEFINER function to safely look up groups by invite code.
-- This bypasses RLS so unauthenticated group data is not exposed,
-- while still allowing invite code joining.
CREATE OR REPLACE FUNCTION find_group_by_invite_code(code TEXT)
RETURNS TABLE(id UUID, name TEXT, description TEXT, icon_url TEXT)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
    SELECT g.id, g.name, g.description, g.icon_url
    FROM groups g
    WHERE g.invite_code = code
      AND (g.invite_code_expires_at IS NULL OR g.invite_code_expires_at > NOW());
END;
$$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION find_group_by_invite_code(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION find_group_by_invite_code(TEXT) TO authenticated;
