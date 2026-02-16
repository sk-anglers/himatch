-- ============================================================
-- Seed Data for Development
-- ============================================================

-- Test users (auth.uid() is managed by Supabase Auth, so we use fixed UUIDs)
INSERT INTO users (id, display_name, email, auth_provider, auth_provider_id) VALUES
    ('11111111-1111-1111-1111-111111111111', 'テスト太郎', 'taro@example.com', 'google', 'google_taro'),
    ('22222222-2222-2222-2222-222222222222', 'テスト花子', 'hanako@example.com', 'apple', 'apple_hanako'),
    ('33333333-3333-3333-3333-333333333333', 'テスト次郎', 'jiro@example.com', 'google', 'google_jiro');

-- Test group
INSERT INTO groups (id, name, description, invite_code, created_by) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '大学の友達', 'いつメン', 'ABCD1234', '11111111-1111-1111-1111-111111111111');

-- Group members
INSERT INTO group_members (group_id, user_id, role) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'owner'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'member'),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'member');

-- Test schedules (March 2026)
INSERT INTO schedules (user_id, title, schedule_type, start_time, end_time, is_all_day) VALUES
    -- Taro: shift worker
    ('11111111-1111-1111-1111-111111111111', '早番', 'shift', '2026-03-15 06:00:00+09', '2026-03-15 15:00:00+09', false),
    ('11111111-1111-1111-1111-111111111111', '休み', 'free', '2026-03-16 00:00:00+09', '2026-03-16 23:59:00+09', true),
    ('11111111-1111-1111-1111-111111111111', '遅番', 'shift', '2026-03-17 14:00:00+09', '2026-03-17 23:00:00+09', false),
    ('11111111-1111-1111-1111-111111111111', '休み', 'free', '2026-03-18 00:00:00+09', '2026-03-18 23:59:00+09', true),
    -- Hanako: student
    ('22222222-2222-2222-2222-222222222222', '授業', 'event', '2026-03-15 09:00:00+09', '2026-03-15 16:00:00+09', false),
    ('22222222-2222-2222-2222-222222222222', '空き', 'free', '2026-03-16 00:00:00+09', '2026-03-16 23:59:00+09', true),
    ('22222222-2222-2222-2222-222222222222', '空き', 'free', '2026-03-17 00:00:00+09', '2026-03-17 23:59:00+09', true),
    ('22222222-2222-2222-2222-222222222222', 'バイト', 'shift', '2026-03-18 10:00:00+09', '2026-03-18 17:00:00+09', false),
    -- Jiro: freelancer
    ('33333333-3333-3333-3333-333333333333', '打ち合わせ', 'event', '2026-03-15 10:00:00+09', '2026-03-15 12:00:00+09', false),
    ('33333333-3333-3333-3333-333333333333', '空き', 'free', '2026-03-16 00:00:00+09', '2026-03-16 23:59:00+09', true),
    ('33333333-3333-3333-3333-333333333333', '空き', 'free', '2026-03-17 18:00:00+09', '2026-03-17 23:59:00+09', false),
    ('33333333-3333-3333-3333-333333333333', '空き', 'free', '2026-03-18 00:00:00+09', '2026-03-18 23:59:00+09', true);

-- Expected suggestions from this data:
-- 3/16: 全員終日空き → "日帰り旅行もOK！" (all_day)
-- 3/17: Taro午前空き + Hanako終日空き + Jiro夜空き → 夜に飲み会 (evening)
