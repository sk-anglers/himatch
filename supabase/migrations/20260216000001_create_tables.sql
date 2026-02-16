-- ============================================================
-- Himatch DB Schema - Initial Migration
-- Based on: docs/architecture.md
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- users: ユーザー情報
-- ============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    VARCHAR(50) NOT NULL,
    email           VARCHAR(255) UNIQUE,
    avatar_url      VARCHAR(500),
    auth_provider   VARCHAR(20) NOT NULL,
    auth_provider_id VARCHAR(255) NOT NULL,
    device_token    VARCHAR(500),
    timezone        VARCHAR(50) NOT NULL DEFAULT 'Asia/Tokyo',
    privacy_default VARCHAR(20) NOT NULL DEFAULT 'friends',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (auth_provider, auth_provider_id),
    CONSTRAINT chk_privacy CHECK (privacy_default IN ('public', 'friends', 'private'))
);

CREATE INDEX idx_users_auth ON users (auth_provider, auth_provider_id);
CREATE INDEX idx_users_email ON users (email) WHERE email IS NOT NULL;

-- ============================================================
-- groups: グループ情報
-- ============================================================
CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(500),
    icon_url        VARCHAR(500),
    invite_code     VARCHAR(20) UNIQUE NOT NULL,
    invite_code_expires_at TIMESTAMPTZ,
    created_by      UUID NOT NULL REFERENCES users(id),
    max_members     INT NOT NULL DEFAULT 20,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_groups_invite_code ON groups (invite_code);
CREATE INDEX idx_groups_created_by ON groups (created_by);

-- ============================================================
-- group_members: グループメンバーシップ
-- ============================================================
CREATE TABLE group_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL DEFAULT 'member',
    nickname        VARCHAR(50),
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (group_id, user_id),
    CONSTRAINT chk_role CHECK (role IN ('owner', 'admin', 'member'))
);

CREATE INDEX idx_group_members_user ON group_members (user_id);
CREATE INDEX idx_group_members_group ON group_members (group_id);

-- ============================================================
-- shift_patterns: シフトパターンテンプレート
-- ============================================================
CREATE TABLE shift_patterns (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    color           VARCHAR(7),
    shifts          JSONB NOT NULL,
    rotation_days   INT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shift_patterns_user ON shift_patterns (user_id);

-- ============================================================
-- schedules: スケジュール/シフト情報
-- ============================================================
CREATE TABLE schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    schedule_type   VARCHAR(20) NOT NULL,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule VARCHAR(255),
    visibility      VARCHAR(20) NOT NULL DEFAULT 'friends',
    color           VARCHAR(7),
    memo            VARCHAR(500),
    shift_pattern_id UUID REFERENCES shift_patterns(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_schedule_time CHECK (end_time > start_time),
    CONSTRAINT chk_schedule_type CHECK (schedule_type IN ('shift', 'event', 'free', 'blocked')),
    CONSTRAINT chk_visibility CHECK (visibility IN ('public', 'friends', 'private'))
);

CREATE INDEX idx_schedules_user_time ON schedules (user_id, start_time, end_time);
CREATE INDEX idx_schedules_type ON schedules (schedule_type);
CREATE INDEX idx_schedules_range ON schedules USING GIST (
    tstzrange(start_time, end_time)
);

-- ============================================================
-- suggestions: 候補日提案
-- ============================================================
CREATE TABLE suggestions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    suggested_date  DATE NOT NULL,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    duration_hours  DECIMAL(4,1) NOT NULL,
    time_category   VARCHAR(30) NOT NULL,
    activity_type   VARCHAR(50) NOT NULL,
    available_members UUID[] NOT NULL,
    total_members   INT NOT NULL,
    availability_ratio DECIMAL(3,2) NOT NULL,
    weather_summary JSONB,
    score           DECIMAL(5,2) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'proposed',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,

    CONSTRAINT chk_time_category CHECK (time_category IN ('morning', 'lunch', 'afternoon', 'evening', 'all_day')),
    CONSTRAINT chk_suggestion_status CHECK (status IN ('proposed', 'accepted', 'declined', 'expired'))
);

CREATE INDEX idx_suggestions_group ON suggestions (group_id);
CREATE INDEX idx_suggestions_date ON suggestions (suggested_date);
CREATE INDEX idx_suggestions_status ON suggestions (status);

-- ============================================================
-- notifications: 通知
-- ============================================================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(30) NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    related_id      UUID,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_notification_type CHECK (type IN (
        'suggestion_new', 'suggestion_accepted', 'group_invite',
        'schedule_updated', 'member_joined'
    ))
);

CREATE INDEX idx_notifications_user ON notifications (user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications (created_at DESC);

-- ============================================================
-- updated_at 自動更新トリガー
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_groups_updated_at
    BEFORE UPDATE ON groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_shift_patterns_updated_at
    BEFORE UPDATE ON shift_patterns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_schedules_updated_at
    BEFORE UPDATE ON schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
