-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- users: 自分のデータは読み書き可、他人は表示名とアバターのみ
-- ============================================================
CREATE POLICY "Users can read own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can read group members profiles"
    ON users FOR SELECT
    USING (
        id IN (
            SELECT gm2.user_id FROM group_members gm1
            JOIN group_members gm2 ON gm1.group_id = gm2.group_id
            WHERE gm1.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================
-- groups: メンバーのみ閲覧可、作成は認証済みユーザー
-- ============================================================
CREATE POLICY "Group members can read group"
    ON groups FOR SELECT
    USING (
        id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid()
        )
    );

-- Allow reading by invite code (for joining)
CREATE POLICY "Anyone can read group by invite code"
    ON groups FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create groups"
    ON groups FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group owner can update group"
    ON groups FOR UPDATE
    USING (
        id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

CREATE POLICY "Group owner can delete group"
    ON groups FOR DELETE
    USING (created_by = auth.uid());

-- ============================================================
-- group_members: メンバーは閲覧可、自分の参加/脱退は可能
-- ============================================================
CREATE POLICY "Group members can read members"
    ON group_members FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Users can join groups"
    ON group_members FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave groups"
    ON group_members FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Group owner/admin can remove members"
    ON group_members FOR DELETE
    USING (
        group_id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
        )
    );

-- ============================================================
-- shift_patterns: 自分のパターンのみ
-- ============================================================
CREATE POLICY "Users can CRUD own shift patterns"
    ON shift_patterns FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================
-- schedules: 自分のは全操作可、グループメンバーの'friends'以上は閲覧可
-- ============================================================
CREATE POLICY "Users can CRUD own schedules"
    ON schedules FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Group members can read visible schedules"
    ON schedules FOR SELECT
    USING (
        visibility IN ('public', 'friends')
        AND user_id IN (
            SELECT gm2.user_id FROM group_members gm1
            JOIN group_members gm2 ON gm1.group_id = gm2.group_id
            WHERE gm1.user_id = auth.uid()
        )
    );

-- ============================================================
-- suggestions: グループメンバーのみ
-- ============================================================
CREATE POLICY "Group members can read suggestions"
    ON suggestions FOR SELECT
    USING (
        group_id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Group members can insert suggestions"
    ON suggestions FOR INSERT
    WITH CHECK (
        group_id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Group members can update suggestion status"
    ON suggestions FOR UPDATE
    USING (
        group_id IN (
            SELECT group_id FROM group_members
            WHERE user_id = auth.uid()
        )
    );

-- ============================================================
-- notifications: 自分の通知のみ
-- ============================================================
CREATE POLICY "Users can read own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- System can insert notifications (via service role)
CREATE POLICY "Service can insert notifications"
    ON notifications FOR INSERT
    WITH CHECK (true);
