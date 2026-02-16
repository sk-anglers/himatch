# 予定管理アプリ - システム設計書

## 1. システムアーキテクチャ

### 全体構成図

```
┌─────────────────────────────────────────────────────────────────────┐
│                         クライアント層                                │
│  ┌─────────────┐                                                    │
│  │   iOS App    │  Swift / SwiftUI                                  │
│  │  (SwiftUI)   │  - ローカルスケジュールキャッシュ (Core Data)        │
│  │             │  - WebSocket クライアント                            │
│  │             │  - Push Notification 受信                           │
│  └──────┬──────┘                                                    │
│         │ HTTPS / WSS                                               │
└─────────┼───────────────────────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────────────────────┐
│         │              API Gateway 層                                │
│  ┌──────▼──────┐                                                    │
│  │   Nginx     │  - TLS 終端                                        │
│  │  (Reverse   │  - レートリミット                                   │
│  │   Proxy)    │  - ロードバランシング                                │
│  └──────┬──────┘                                                    │
└─────────┼───────────────────────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────────────────────┐
│         │            アプリケーション層                               │
│  ┌──────▼──────┐  ┌──────────────┐  ┌──────────────┐               │
│  │  REST API   │  │  WebSocket   │  │   Worker     │               │
│  │  Server     │  │  Server      │  │  (Background)│               │
│  │  (Node.js / │  │  (リアルタイム │  │  - 候補日計算 │               │
│  │  Express)   │  │   同期)      │  │  - 天気取得   │               │
│  └──────┬──────┘  └──────┬───────┘  │  - 通知送信   │               │
│         │                │          └──────┬───────┘               │
│         │                │                 │                        │
│  ┌──────▼────────────────▼─────────────────▼───────┐               │
│  │                  共通サービス層                    │               │
│  │  ┌────────────┐ ┌────────────┐ ┌──────────────┐ │               │
│  │  │ Auth       │ │ Schedule   │ │ Suggestion   │ │               │
│  │  │ Service    │ │ Service    │ │ Engine       │ │               │
│  │  └────────────┘ └────────────┘ └──────────────┘ │               │
│  │  ┌────────────┐ ┌────────────┐ ┌──────────────┐ │               │
│  │  │ Group      │ │ Weather    │ │ Notification │ │               │
│  │  │ Service    │ │ Service    │ │ Service      │ │               │
│  │  └────────────┘ └────────────┘ └──────────────┘ │               │
│  └─────────────────────────────────────────────────┘               │
└─────────┬──────────────────┬──────────────────┬─────────────────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────────────────┐
│         │          データ層 │                  │                     │
│  ┌──────▼──────┐  ┌───────▼───────┐  ┌───────▼──────┐             │
│  │ PostgreSQL  │  │    Redis      │  │    S3        │             │
│  │ (メインDB)  │  │ - セッション   │  │ (プロフィール │             │
│  │             │  │ - キャッシュ   │  │  画像等)     │             │
│  │             │  │ - Pub/Sub     │  │              │             │
│  └─────────────┘  └───────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
          │
┌─────────┼───────────────────────────────────────────────────────────┐
│         │              外部サービス連携                               │
│  ┌──────▼──────┐  ┌───────────────┐  ┌──────────────┐             │
│  │ Apple       │  │ OpenWeather   │  │ APNs         │             │
│  │ Sign In     │  │ API           │  │ (Push通知)   │             │
│  ├─────────────┤  │ (天気予報)    │  │              │             │
│  │ LINE Login  │  │               │  │              │             │
│  └─────────────┘  └───────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

### 技術スタック

| レイヤー | 技術 | 理由 |
|---------|------|------|
| iOS クライアント | Swift / SwiftUI | Apple 標準、宣言的UI |
| API サーバー | Node.js + Express (TypeScript) | WebSocket との親和性、非同期I/O |
| WebSocket | Socket.IO | 自動再接続、フォールバック対応 |
| データベース | PostgreSQL 16 | JSONB対応、堅牢なリレーショナルDB |
| キャッシュ / Pub/Sub | Redis 7 | WebSocket のスケールアウト、セッション管理 |
| バックグラウンド処理 | Bull Queue (Redis-backed) | ジョブキュー、リトライ機構 |
| 認証 | JWT + OAuth 2.0 | Apple Sign In / LINE Login 対応 |
| Push 通知 | APNs (Apple Push Notification service) | iOS ネイティブ |
| 天気 API | OpenWeatherMap API | 無料枠あり、7日間予報対応 |
| インフラ | AWS (ECS Fargate) or GCP (Cloud Run) | コンテナベース、スケーラブル |

---

## 2. データベーススキーマ設計

### ER図（テキスト）

```
users 1──N group_members N──1 groups
  │                              │
  │ 1                            │
  │                              │
  └──N schedules                 └──N suggestions
       │
       └── shift_patterns (テンプレート)

weather_cache (独立)
notifications (users に紐づく)
```

### テーブル定義

```sql
-- ============================================================
-- users: ユーザー情報
-- ============================================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    VARCHAR(50) NOT NULL,
    email           VARCHAR(255) UNIQUE,          -- NULL可（LINE Loginはメール不要の場合あり）
    avatar_url      VARCHAR(500),
    auth_provider   VARCHAR(20) NOT NULL,          -- 'apple' | 'line'
    auth_provider_id VARCHAR(255) NOT NULL,        -- 外部IDプロバイダのユーザーID
    device_token    VARCHAR(500),                  -- APNs デバイストークン
    timezone        VARCHAR(50) NOT NULL DEFAULT 'Asia/Tokyo',
    privacy_default VARCHAR(20) NOT NULL DEFAULT 'friends',  -- 'public' | 'friends' | 'private'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (auth_provider, auth_provider_id)
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
    invite_code     VARCHAR(20) UNIQUE NOT NULL,   -- 招待コード（8文字のランダム文字列）
    invite_code_expires_at TIMESTAMPTZ,            -- NULL = 無期限
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
    role            VARCHAR(20) NOT NULL DEFAULT 'member',  -- 'owner' | 'admin' | 'member'
    nickname        VARCHAR(50),                   -- グループ内ニックネーム（任意）
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (group_id, user_id)
);

CREATE INDEX idx_group_members_user ON group_members (user_id);
CREATE INDEX idx_group_members_group ON group_members (group_id);

-- ============================================================
-- schedules: スケジュール/シフト情報
-- ============================================================
CREATE TABLE schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,          -- '早番', '遅番', 'デート', '空き' など
    schedule_type   VARCHAR(20) NOT NULL,            -- 'shift' | 'event' | 'free' | 'blocked'
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule VARCHAR(255),                    -- iCal RRULE形式: 'FREQ=WEEKLY;BYDAY=MO,WE,FR'
    visibility      VARCHAR(20) NOT NULL DEFAULT 'friends',  -- 'public' | 'friends' | 'private'
    color           VARCHAR(7),                      -- '#FF5733' 形式
    memo            VARCHAR(500),
    shift_pattern_id UUID REFERENCES shift_patterns(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_schedule_time CHECK (end_time > start_time)
);

CREATE INDEX idx_schedules_user_time ON schedules (user_id, start_time, end_time);
CREATE INDEX idx_schedules_type ON schedules (schedule_type);
CREATE INDEX idx_schedules_range ON schedules USING GIST (
    tstzrange(start_time, end_time)
);

-- ============================================================
-- shift_patterns: シフトパターンテンプレート
-- ============================================================
CREATE TABLE shift_patterns (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,          -- '早番パターン', '3交代A' など
    color           VARCHAR(7),
    shifts          JSONB NOT NULL,                 -- シフトの定義配列
    -- shifts の例:
    -- [
    --   {"label": "早番", "start": "06:00", "end": "15:00", "color": "#4CAF50"},
    --   {"label": "遅番", "start": "14:00", "end": "23:00", "color": "#FF9800"},
    --   {"label": "夜勤", "start": "22:00", "end": "07:00", "color": "#9C27B0"},
    --   {"label": "休み", "start": null, "end": null, "color": "#2196F3"}
    -- ]
    rotation_days   INT,                            -- ローテーション周期（日数）。NULL = ローテーションなし
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shift_patterns_user ON shift_patterns (user_id);

-- ============================================================
-- suggestions: 候補日提案
-- ============================================================
CREATE TABLE suggestions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    suggested_date  DATE NOT NULL,
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    duration_hours  DECIMAL(4,1) NOT NULL,          -- 空き時間の長さ
    time_category   VARCHAR(30) NOT NULL,            -- 'morning' | 'lunch' | 'afternoon' | 'evening' | 'all_day'
    activity_type   VARCHAR(50) NOT NULL,            -- '飲み会' | '日帰り旅行' | 'ランチ' | 'カフェ' | 'モーニング' 等
    available_members UUID[] NOT NULL,               -- 参加可能メンバーのID配列
    total_members   INT NOT NULL,
    availability_ratio DECIMAL(3,2) NOT NULL,        -- 参加可能率 (0.00-1.00)
    weather_summary JSONB,                           -- {"condition": "晴れ", "temp_high": 25, "temp_low": 18, "icon": "01d"}
    score           DECIMAL(5,2) NOT NULL,           -- 総合スコア（高いほどおすすめ）
    status          VARCHAR(20) NOT NULL DEFAULT 'proposed',  -- 'proposed' | 'accepted' | 'declined' | 'expired'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL             -- 提案の有効期限
);

CREATE INDEX idx_suggestions_group ON suggestions (group_id, status);
CREATE INDEX idx_suggestions_date ON suggestions (suggested_date);
CREATE INDEX idx_suggestions_score ON suggestions (group_id, score DESC);

-- ============================================================
-- weather_cache: 天気予報キャッシュ
-- ============================================================
CREATE TABLE weather_cache (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_key    VARCHAR(100) NOT NULL,           -- '35.6762,139.6503' (緯度,経度) or 'Tokyo'
    forecast_date   DATE NOT NULL,
    condition       VARCHAR(50) NOT NULL,            -- 'Clear', 'Clouds', 'Rain', 'Snow' 等
    condition_ja    VARCHAR(50) NOT NULL,            -- '晴れ', '曇り', '雨', '雪' 等
    icon_code       VARCHAR(10) NOT NULL,            -- OpenWeatherMap icon code
    temp_high       DECIMAL(4,1),                    -- 最高気温 (℃)
    temp_low        DECIMAL(4,1),                    -- 最低気温 (℃)
    humidity        INT,                             -- 湿度 (%)
    wind_speed      DECIMAL(4,1),                    -- 風速 (m/s)
    rain_probability DECIMAL(3,2),                   -- 降水確率 (0.00-1.00)
    raw_data        JSONB,                           -- API生レスポンス
    fetched_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,            -- キャッシュ有効期限

    UNIQUE (location_key, forecast_date)
);

CREATE INDEX idx_weather_cache_lookup ON weather_cache (location_key, forecast_date);
CREATE INDEX idx_weather_cache_expires ON weather_cache (expires_at);

-- ============================================================
-- notifications: 通知履歴
-- ============================================================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(50) NOT NULL,            -- 'suggestion_new' | 'group_invite' | 'schedule_updated' | 'member_joined'
    title           VARCHAR(200) NOT NULL,
    body            VARCHAR(500) NOT NULL,
    data            JSONB,                           -- プッシュ通知のペイロード {"group_id": "...", "suggestion_id": "..."}
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    is_pushed       BOOLEAN NOT NULL DEFAULT FALSE,  -- APNs送信済みか
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications (user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_push ON notifications (is_pushed) WHERE is_pushed = FALSE;
```

---

## 3. RESTful API 設計

### 共通仕様

- **Base URL**: `https://api.schedule-app.example.com/v1`
- **認証**: `Authorization: Bearer <JWT>`
- **Content-Type**: `application/json`
- **エラーレスポンス形式**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "start_time must be before end_time",
    "details": [
      {"field": "start_time", "message": "must be before end_time"}
    ]
  }
}
```

### 3.1 認証 API

#### POST /auth/login
外部プロバイダ経由のログイン（既存ユーザー）

```
POST /v1/auth/login
```

**Request:**
```json
{
  "provider": "apple",
  "id_token": "eyJhbGciOiJSUzI1NiI...",
  "device_token": "abc123def456..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiI...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2g...",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "display_name": "田中太郎",
    "email": "tanaka@example.com",
    "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg",
    "auth_provider": "apple",
    "timezone": "Asia/Tokyo"
  }
}
```

#### POST /auth/register
新規ユーザー登録

```
POST /v1/auth/register
```

**Request:**
```json
{
  "provider": "line",
  "id_token": "eyJhbGciOiJSUzI1NiI...",
  "display_name": "田中太郎",
  "device_token": "abc123def456..."
}
```

**Response (201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiI...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2g...",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "display_name": "田中太郎",
    "email": null,
    "avatar_url": null,
    "auth_provider": "line",
    "timezone": "Asia/Tokyo"
  }
}
```

#### POST /auth/refresh
トークンリフレッシュ

```
POST /v1/auth/refresh
```

**Request:**
```json
{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2g..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiI...(new)",
  "refresh_token": "bmV3IHJlZnJlc2ggdG9rZW4...(new)",
  "expires_in": 3600
}
```

---

### 3.2 ユーザー API

#### GET /users/me
認証済みユーザーの情報取得

```
GET /v1/users/me
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "display_name": "田中太郎",
  "email": "tanaka@example.com",
  "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg",
  "auth_provider": "apple",
  "timezone": "Asia/Tokyo",
  "privacy_default": "friends",
  "created_at": "2026-01-15T10:30:00Z"
}
```

#### PUT /users/me
ユーザー情報更新

```
PUT /v1/users/me
Authorization: Bearer <token>
```

**Request:**
```json
{
  "display_name": "たなかたろう",
  "timezone": "Asia/Tokyo",
  "privacy_default": "friends"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "display_name": "たなかたろう",
  "email": "tanaka@example.com",
  "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg",
  "auth_provider": "apple",
  "timezone": "Asia/Tokyo",
  "privacy_default": "friends",
  "updated_at": "2026-02-16T08:00:00Z"
}
```

---

### 3.3 グループ API

#### POST /groups
グループ作成

```
POST /v1/groups
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "大学メンバー",
  "description": "大学の友達グループ",
  "max_members": 10
}
```

**Response (201):**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "name": "大学メンバー",
  "description": "大学の友達グループ",
  "icon_url": null,
  "invite_code": "AB3F8K2P",
  "max_members": 10,
  "created_by": "550e8400-e29b-41d4-a716-446655440000",
  "members": [
    {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "display_name": "田中太郎",
      "role": "owner",
      "joined_at": "2026-02-16T08:00:00Z"
    }
  ],
  "created_at": "2026-02-16T08:00:00Z"
}
```

#### GET /groups
自分が所属するグループ一覧

```
GET /v1/groups
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "groups": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "name": "大学メンバー",
      "description": "大学の友達グループ",
      "icon_url": null,
      "member_count": 5,
      "my_role": "owner",
      "created_at": "2026-02-16T08:00:00Z"
    }
  ]
}
```

#### GET /groups/:id
グループ詳細取得

```
GET /v1/groups/660e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "name": "大学メンバー",
  "description": "大学の友達グループ",
  "icon_url": null,
  "invite_code": "AB3F8K2P",
  "max_members": 10,
  "created_by": "550e8400-e29b-41d4-a716-446655440000",
  "members": [
    {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "display_name": "田中太郎",
      "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg",
      "role": "owner",
      "nickname": null,
      "joined_at": "2026-02-16T08:00:00Z"
    },
    {
      "user_id": "770e8400-e29b-41d4-a716-446655440002",
      "display_name": "鈴木花子",
      "avatar_url": "https://cdn.example.com/avatars/770e8400.jpg",
      "role": "member",
      "nickname": "はなちゃん",
      "joined_at": "2026-02-16T09:00:00Z"
    }
  ],
  "created_at": "2026-02-16T08:00:00Z"
}
```

#### PUT /groups/:id
グループ情報更新（owner / admin のみ）

```
PUT /v1/groups/660e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "大学メンバー 2026",
  "description": "大学の友達グループ（更新版）"
}
```

**Response (200):** 更新後のグループオブジェクト（GET /groups/:id と同形式）

#### DELETE /groups/:id
グループ削除（owner のみ）

```
DELETE /v1/groups/660e8400-e29b-41d4-a716-446655440001
Authorization: Bearer <token>
```

**Response (204):** No Content

#### POST /groups/:id/join
招待コードでグループに参加

```
POST /v1/groups/660e8400-e29b-41d4-a716-446655440001/join
Authorization: Bearer <token>
```

**Request:**
```json
{
  "invite_code": "AB3F8K2P"
}
```

**Response (200):**
```json
{
  "group_id": "660e8400-e29b-41d4-a716-446655440001",
  "user_id": "880e8400-e29b-41d4-a716-446655440003",
  "role": "member",
  "joined_at": "2026-02-16T10:00:00Z"
}
```

#### DELETE /groups/:id/members/:userId
メンバー削除（owner/admin）、または自分が脱退

```
DELETE /v1/groups/660e8400.../members/880e8400...
Authorization: Bearer <token>
```

**Response (204):** No Content

---

### 3.4 スケジュール API

#### POST /schedules
スケジュール登録

```
POST /v1/schedules
Authorization: Bearer <token>
```

**Request:**
```json
{
  "title": "早番",
  "schedule_type": "shift",
  "start_time": "2026-02-20T06:00:00+09:00",
  "end_time": "2026-02-20T15:00:00+09:00",
  "is_all_day": false,
  "visibility": "friends",
  "color": "#4CAF50",
  "memo": "通常の早番シフト"
}
```

**Response (201):**
```json
{
  "id": "990e8400-e29b-41d4-a716-446655440010",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "早番",
  "schedule_type": "shift",
  "start_time": "2026-02-20T06:00:00+09:00",
  "end_time": "2026-02-20T15:00:00+09:00",
  "is_all_day": false,
  "recurrence_rule": null,
  "visibility": "friends",
  "color": "#4CAF50",
  "memo": "通常の早番シフト",
  "created_at": "2026-02-16T08:00:00Z"
}
```

#### POST /schedules/bulk
一括登録（シフト表まとめて入力用）

```
POST /v1/schedules/bulk
Authorization: Bearer <token>
```

**Request:**
```json
{
  "schedules": [
    {
      "title": "早番",
      "schedule_type": "shift",
      "start_time": "2026-02-20T06:00:00+09:00",
      "end_time": "2026-02-20T15:00:00+09:00",
      "color": "#4CAF50"
    },
    {
      "title": "遅番",
      "schedule_type": "shift",
      "start_time": "2026-02-21T14:00:00+09:00",
      "end_time": "2026-02-21T23:00:00+09:00",
      "color": "#FF9800"
    },
    {
      "title": "休み",
      "schedule_type": "free",
      "start_time": "2026-02-22T00:00:00+09:00",
      "end_time": "2026-02-22T23:59:59+09:00",
      "is_all_day": true,
      "color": "#2196F3"
    }
  ]
}
```

**Response (201):**
```json
{
  "created": 3,
  "schedules": [ ... ]
}
```

#### GET /schedules
自分のスケジュール取得

```
GET /v1/schedules?start_date=2026-02-01&end_date=2026-02-28
Authorization: Bearer <token>
```

**Query Parameters:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| start_date | string (YYYY-MM-DD) | Yes | 取得開始日 |
| end_date | string (YYYY-MM-DD) | Yes | 取得終了日 |
| schedule_type | string | No | フィルタ: 'shift', 'event', 'free', 'blocked' |

**Response (200):**
```json
{
  "schedules": [
    {
      "id": "990e8400-e29b-41d4-a716-446655440010",
      "title": "早番",
      "schedule_type": "shift",
      "start_time": "2026-02-20T06:00:00+09:00",
      "end_time": "2026-02-20T15:00:00+09:00",
      "is_all_day": false,
      "color": "#4CAF50",
      "memo": "通常の早番シフト"
    }
  ]
}
```

#### GET /groups/:groupId/schedules
グループメンバー全員のスケジュール取得

```
GET /v1/groups/660e8400.../schedules?start_date=2026-02-01&end_date=2026-02-28
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "members": [
    {
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "display_name": "田中太郎",
      "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg",
      "schedules": [
        {
          "id": "990e8400...",
          "title": "早番",
          "schedule_type": "shift",
          "start_time": "2026-02-20T06:00:00+09:00",
          "end_time": "2026-02-20T15:00:00+09:00",
          "is_all_day": false,
          "color": "#4CAF50"
        }
      ]
    },
    {
      "user_id": "770e8400-e29b-41d4-a716-446655440002",
      "display_name": "鈴木花子",
      "avatar_url": "https://cdn.example.com/avatars/770e8400.jpg",
      "schedules": [
        {
          "title": "休み",
          "schedule_type": "free",
          "start_time": "2026-02-20T00:00:00+09:00",
          "end_time": "2026-02-20T23:59:59+09:00",
          "is_all_day": true,
          "color": "#2196F3"
        }
      ]
    }
  ]
}
```

**注意**: `visibility: 'private'` のスケジュールは本人以外には返却しない。`visibility: 'friends'` は同一グループメンバーにのみ返却。

#### PUT /schedules/:id
スケジュール更新

```
PUT /v1/schedules/990e8400...
Authorization: Bearer <token>
```

**Request:**
```json
{
  "title": "遅番に変更",
  "start_time": "2026-02-20T14:00:00+09:00",
  "end_time": "2026-02-20T23:00:00+09:00",
  "color": "#FF9800"
}
```

**Response (200):** 更新後のスケジュールオブジェクト

#### DELETE /schedules/:id
スケジュール削除

```
DELETE /v1/schedules/990e8400...
Authorization: Bearer <token>
```

**Response (204):** No Content

---

### 3.5 シフトパターン API

#### POST /shift-patterns
シフトパターンテンプレート作成

```
POST /v1/shift-patterns
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "3交代シフト",
  "shifts": [
    {"label": "早番", "start": "06:00", "end": "15:00", "color": "#4CAF50"},
    {"label": "遅番", "start": "14:00", "end": "23:00", "color": "#FF9800"},
    {"label": "夜勤", "start": "22:00", "end": "07:00", "color": "#9C27B0"},
    {"label": "休み", "start": null, "end": null, "color": "#2196F3"}
  ],
  "rotation_days": 4
}
```

**Response (201):**
```json
{
  "id": "aa0e8400-e29b-41d4-a716-446655440020",
  "name": "3交代シフト",
  "shifts": [ ... ],
  "rotation_days": 4,
  "created_at": "2026-02-16T08:00:00Z"
}
```

#### GET /shift-patterns
自分のシフトパターン一覧

```
GET /v1/shift-patterns
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "patterns": [
    {
      "id": "aa0e8400...",
      "name": "3交代シフト",
      "shifts": [ ... ],
      "rotation_days": 4
    }
  ]
}
```

#### POST /shift-patterns/:id/apply
シフトパターンを日付範囲に適用してスケジュールを一括生成

```
POST /v1/shift-patterns/aa0e8400.../apply
Authorization: Bearer <token>
```

**Request:**
```json
{
  "start_date": "2026-03-01",
  "end_date": "2026-03-31",
  "assignments": [
    {"date": "2026-03-01", "shift_index": 0},
    {"date": "2026-03-02", "shift_index": 1},
    {"date": "2026-03-03", "shift_index": 2},
    {"date": "2026-03-04", "shift_index": 3}
  ]
}
```

**Response (201):**
```json
{
  "created": 31,
  "schedules": [ ... ]
}
```

---

### 3.6 候補日提案 API

#### GET /groups/:groupId/suggestions
グループの候補日提案を取得

```
GET /v1/groups/660e8400.../suggestions?start_date=2026-02-20&end_date=2026-03-20&min_members=3
Authorization: Bearer <token>
```

**Query Parameters:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| start_date | string | Yes | 検索開始日 |
| end_date | string | Yes | 検索終了日 |
| min_members | int | No | 最低参加人数（デフォルト: グループ全員） |
| activity_type | string | No | フィルタ: '飲み会', 'ランチ' 等 |

**Response (200):**
```json
{
  "suggestions": [
    {
      "id": "bb0e8400-e29b-41d4-a716-446655440030",
      "suggested_date": "2026-02-22",
      "start_time": "2026-02-22T10:00:00+09:00",
      "end_time": "2026-02-22T22:00:00+09:00",
      "duration_hours": 12.0,
      "time_category": "all_day",
      "activity_type": "日帰り旅行",
      "available_members": [
        {
          "user_id": "550e8400...",
          "display_name": "田中太郎",
          "avatar_url": "https://cdn.example.com/avatars/550e8400.jpg"
        },
        {
          "user_id": "770e8400...",
          "display_name": "鈴木花子",
          "avatar_url": "https://cdn.example.com/avatars/770e8400.jpg"
        }
      ],
      "total_members": 5,
      "availability_ratio": 0.40,
      "weather": {
        "condition": "晴れ",
        "icon": "01d",
        "temp_high": 18,
        "temp_low": 8,
        "rain_probability": 0.10
      },
      "score": 85.5,
      "status": "proposed"
    },
    {
      "id": "cc0e8400...",
      "suggested_date": "2026-02-22",
      "start_time": "2026-02-22T18:00:00+09:00",
      "end_time": "2026-02-22T23:00:00+09:00",
      "duration_hours": 5.0,
      "time_category": "evening",
      "activity_type": "飲み会",
      "available_members": [ ... ],
      "total_members": 5,
      "availability_ratio": 0.80,
      "weather": {
        "condition": "晴れ",
        "icon": "01d",
        "temp_high": 18,
        "temp_low": 8,
        "rain_probability": 0.10
      },
      "score": 92.0,
      "status": "proposed"
    }
  ],
  "generated_at": "2026-02-16T08:00:00Z"
}
```

#### POST /groups/:groupId/suggestions/:id/respond
提案への応答

```
POST /v1/groups/660e8400.../suggestions/bb0e8400.../respond
Authorization: Bearer <token>
```

**Request:**
```json
{
  "action": "accept"
}
```

**Response (200):**
```json
{
  "suggestion_id": "bb0e8400...",
  "status": "accepted",
  "updated_at": "2026-02-16T09:00:00Z"
}
```

---

### 3.7 天気 API

#### GET /weather
天気予報取得

```
GET /v1/weather?date=2026-02-22&location=Tokyo
Authorization: Bearer <token>
```

**Query Parameters:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|-----|------|
| date | string (YYYY-MM-DD) | Yes | 天気を取得する日付 |
| location | string | No | 地名（デフォルト: 'Tokyo'） |
| lat | decimal | No | 緯度（locationの代替） |
| lon | decimal | No | 経度（locationの代替） |

**Response (200):**
```json
{
  "date": "2026-02-22",
  "location": "Tokyo",
  "condition": "晴れ",
  "icon": "01d",
  "temp_high": 18,
  "temp_low": 8,
  "humidity": 45,
  "wind_speed": 3.5,
  "rain_probability": 0.10,
  "cached": true,
  "fetched_at": "2026-02-16T06:00:00Z"
}
```

---

### 3.8 通知 API

#### GET /notifications
通知一覧取得

```
GET /v1/notifications?limit=20&offset=0
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "dd0e8400...",
      "type": "suggestion_new",
      "title": "新しい候補日があります",
      "body": "「大学メンバー」グループで2/22(日)に全員集まれそうです！",
      "data": {
        "group_id": "660e8400...",
        "suggestion_id": "bb0e8400..."
      },
      "is_read": false,
      "created_at": "2026-02-16T08:00:00Z"
    }
  ],
  "total": 15,
  "unread_count": 3
}
```

#### PUT /notifications/:id/read
通知を既読にする

```
PUT /v1/notifications/dd0e8400.../read
Authorization: Bearer <token>
```

**Response (204):** No Content

---

## 4. 候補日提案アルゴリズム（コアロジック）

### 擬似コード

```typescript
// ============================================================
// 候補日提案エンジン (Suggestion Engine)
// ============================================================

interface TimeSlot {
  start: DateTime;
  end: DateTime;
}

interface Suggestion {
  date: Date;
  start: DateTime;
  end: DateTime;
  durationHours: number;
  timeCategory: 'morning' | 'lunch' | 'afternoon' | 'evening' | 'all_day';
  activityType: string;
  availableMembers: User[];
  weather: WeatherData | null;
  score: number;
}

async function generateSuggestions(
  groupId: string,
  startDate: Date,
  endDate: Date,
  minMembers?: number
): Promise<Suggestion[]> {

  // ── Step 0: データ取得 ──────────────────────────────
  const group = await getGroup(groupId);
  const members = await getGroupMembers(groupId);
  minMembers = minMembers ?? members.length;

  // 各メンバーのスケジュールを取得
  const memberSchedules: Map<string, Schedule[]> = new Map();
  for (const member of members) {
    const schedules = await getSchedules(member.id, startDate, endDate);
    memberSchedules.set(member.id, schedules);
  }

  // ── Step 1: 各メンバーの空き時間を抽出 ─────────────
  const memberFreeSlots: Map<string, TimeSlot[]> = new Map();

  for (const [memberId, schedules] of memberSchedules) {
    const freeSlots = extractFreeSlots(schedules, startDate, endDate);
    memberFreeSlots.set(memberId, freeSlots);
  }

  // ── Step 2: 共通の空き時間帯を検出 ─────────────────
  const commonSlots = findCommonFreeSlots(memberFreeSlots, minMembers);

  // ── Step 3: 時間帯分類とアクティビティ提案 ─────────
  const categorizedSlots = commonSlots.map(slot => categorizeTimeSlot(slot));

  // ── Step 4: 天気情報を統合 ──────────────────────────
  const slotsWithWeather = await enrichWithWeather(categorizedSlots);

  // ── Step 5: スコアリングと並び替え ──────────────────
  const scored = slotsWithWeather.map(slot => calculateScore(slot, members.length));
  scored.sort((a, b) => b.score - a.score);

  return scored;
}

// ────────────────────────────────────────────────────────────
// Step 1: 空き時間抽出
// ────────────────────────────────────────────────────────────
function extractFreeSlots(
  schedules: Schedule[],
  startDate: Date,
  endDate: Date
): TimeSlot[] {
  const freeSlots: TimeSlot[] = [];

  // 日付ごとに処理
  for (let date = startDate; date <= endDate; date = addDays(date, 1)) {
    const dayStart = setTime(date, 9, 0);   // 活動可能開始: 9:00
    const dayEnd = setTime(date, 23, 0);     // 活動可能終了: 23:00

    // その日のスケジュール（'shift', 'event', 'blocked' のみ。'free' は空きとみなす）
    const daySchedules = schedules
      .filter(s => isSameDay(s.startTime, date))
      .filter(s => s.scheduleType !== 'free')
      .sort((a, b) => a.startTime - b.startTime);

    // 明示的に 'free' マークされた時間帯を優先空きに
    const explicitFree = schedules
      .filter(s => isSameDay(s.startTime, date) && s.scheduleType === 'free');

    if (explicitFree.length > 0) {
      // 明示的な空き時間を返す
      for (const free of explicitFree) {
        freeSlots.push({ start: free.startTime, end: free.endTime });
      }
    } else if (daySchedules.length === 0) {
      // 予定なし → 終日空き
      freeSlots.push({ start: dayStart, end: dayEnd });
    } else {
      // 予定の隙間を空き時間として抽出
      let cursor = dayStart;
      for (const schedule of daySchedules) {
        if (cursor < schedule.startTime) {
          freeSlots.push({ start: cursor, end: schedule.startTime });
        }
        cursor = max(cursor, schedule.endTime);
      }
      if (cursor < dayEnd) {
        freeSlots.push({ start: cursor, end: dayEnd });
      }
    }
  }

  // 最低1時間未満の隙間は除外
  return freeSlots.filter(slot =>
    differenceInHours(slot.end, slot.start) >= 1.0
  );
}

// ────────────────────────────────────────────────────────────
// Step 2: 共通空き時間の検出
// ────────────────────────────────────────────────────────────
function findCommonFreeSlots(
  memberFreeSlots: Map<string, TimeSlot[]>,
  minMembers: number
): CommonSlot[] {
  const results: CommonSlot[] = [];
  const memberIds = Array.from(memberFreeSlots.keys());

  // 全メンバーの全空きスロットのイベントポイントを収集
  interface Event {
    time: DateTime;
    type: 'start' | 'end';
    memberId: string;
  }

  const events: Event[] = [];
  for (const [memberId, slots] of memberFreeSlots) {
    for (const slot of slots) {
      events.push({ time: slot.start, type: 'start', memberId });
      events.push({ time: slot.end, type: 'end', memberId });
    }
  }

  // 時刻順にソート（同時刻は end を先に処理）
  events.sort((a, b) => {
    if (a.time !== b.time) return a.time - b.time;
    return a.type === 'end' ? -1 : 1;
  });

  // スイープラインで共通空き時間を検出
  const activeMembers = new Set<string>();
  let segmentStart: DateTime | null = null;

  for (const event of events) {
    const prevCount = activeMembers.size;

    if (event.type === 'start') {
      activeMembers.add(event.memberId);
    } else {
      activeMembers.delete(event.memberId);
    }

    const currentCount = activeMembers.size;

    // minMembers 以上になった瞬間：区間開始
    if (prevCount < minMembers && currentCount >= minMembers) {
      segmentStart = event.time;
    }

    // minMembers を下回った瞬間：区間終了
    if (prevCount >= minMembers && currentCount < minMembers) {
      if (segmentStart) {
        const durationHours = differenceInHours(event.time, segmentStart);
        if (durationHours >= 1.0) {
          results.push({
            start: segmentStart,
            end: event.time,
            durationHours,
            availableMembers: Array.from(activeMembers), // この時点の参加可能メンバー
            date: toDate(segmentStart)
          });
        }
        segmentStart = null;
      }
    }
  }

  return results;
}

// ────────────────────────────────────────────────────────────
// Step 3: 時間帯分類とアクティビティ提案
// ────────────────────────────────────────────────────────────
function categorizeTimeSlot(slot: CommonSlot): CategorizedSlot {
  const startHour = slot.start.getHours();
  const endHour = slot.end.getHours();
  const duration = slot.durationHours;

  let timeCategory: string;
  let activityTypes: string[];

  // 終日 (10時間以上、開始が午前)
  if (duration >= 10 && startHour <= 10) {
    timeCategory = 'all_day';
    activityTypes = ['日帰り旅行', '遊園地・テーマパーク', 'BBQ', 'ドライブ'];
  }
  // 午前 (9:00-12:00 の間で2時間以上)
  else if (startHour >= 9 && endHour <= 13 && duration >= 1.5) {
    timeCategory = 'morning';
    activityTypes = ['モーニング', 'ブランチ', '朝カフェ'];
  }
  // ランチ帯 (11:00-14:00 を含む2時間以上)
  else if (startHour <= 12 && endHour >= 13 && duration >= 2) {
    timeCategory = 'lunch';
    activityTypes = ['ランチ', 'カフェ'];
  }
  // 午後 (12:00-18:00 の間で3時間以上)
  else if (startHour >= 12 && endHour <= 18 && duration >= 3) {
    timeCategory = 'afternoon';
    activityTypes = ['カフェ', 'ショッピング', '映画', 'カラオケ'];
  }
  // 夕方〜夜 (18:00以降で2時間以上)
  else if (startHour >= 17 && duration >= 2) {
    timeCategory = 'evening';
    activityTypes = ['飲み会', '夕食', '居酒屋'];
  }
  // 長い午後〜夜 (14:00-23:00 で6時間以上)
  else if (startHour >= 12 && endHour >= 20 && duration >= 6) {
    timeCategory = 'afternoon';
    activityTypes = ['遊び', 'カラオケ', 'ボウリング', '飲み会'];
  }
  // デフォルト
  else {
    timeCategory = 'other';
    activityTypes = ['お出かけ'];
  }

  // 最も適切なアクティビティを1つ選択（時間帯と長さから）
  const primaryActivity = activityTypes[0];

  return {
    ...slot,
    timeCategory,
    activityType: primaryActivity,
    alternativeActivities: activityTypes.slice(1)
  };
}

// ────────────────────────────────────────────────────────────
// Step 4: 天気情報の統合
// ────────────────────────────────────────────────────────────
async function enrichWithWeather(
  slots: CategorizedSlot[]
): Promise<CategorizedSlotWithWeather[]> {
  // ユニークな日付を抽出
  const uniqueDates = [...new Set(slots.map(s => formatDate(s.date)))];

  // 天気情報を一括取得（キャッシュ活用）
  const weatherMap: Map<string, WeatherData> = new Map();
  for (const date of uniqueDates) {
    const weather = await getWeatherWithCache(date, 'Tokyo');
    if (weather) {
      weatherMap.set(date, weather);
    }
  }

  return slots.map(slot => {
    const weather = weatherMap.get(formatDate(slot.date)) ?? null;

    // 天気に基づくアクティビティ調整
    let adjustedActivity = slot.activityType;
    if (weather) {
      if (weather.rainProbability > 0.6) {
        // 雨の可能性が高い → 屋内アクティビティに変更
        adjustedActivity = adjustForRain(slot.activityType);
      }
      if (weather.tempHigh > 35) {
        // 猛暑 → 屋内推奨
        adjustedActivity = adjustForHeat(slot.activityType);
      }
    }

    return {
      ...slot,
      activityType: adjustedActivity,
      weather
    };
  });
}

// 雨の場合のアクティビティ調整
function adjustForRain(activity: string): string {
  const rainAlternatives: Record<string, string> = {
    '日帰り旅行': 'ショッピングモール',
    'BBQ': '焼肉',
    'ドライブ': '映画',
    '遊園地・テーマパーク': '水族館・室内施設',
  };
  return rainAlternatives[activity] ?? activity;
}

// ────────────────────────────────────────────────────────────
// Step 5: スコアリング（優先順位付け）
// ────────────────────────────────────────────────────────────
function calculateScore(
  slot: CategorizedSlotWithWeather,
  totalMembers: number
): number {
  let score = 0;

  // (a) 参加率スコア (最大40点)
  // 全員参加 = 40点、半数 = 20点
  const participationRate = slot.availableMembers.length / totalMembers;
  score += participationRate * 40;

  // (b) 天気スコア (最大20点)
  if (slot.weather) {
    // 晴れ = 20点、曇り = 15点、雨 = 5点
    const weatherScores: Record<string, number> = {
      'Clear': 20,
      'Clouds': 15,
      'Drizzle': 10,
      'Rain': 5,
      'Snow': 3,
      'Thunderstorm': 2
    };
    score += weatherScores[slot.weather.condition] ?? 10;

    // 降水確率による減点
    score -= slot.weather.rainProbability * 10;
  } else {
    score += 10; // 天気不明は中間値
  }

  // (c) 時間の長さスコア (最大15点)
  // 長い方が価値が高い（ただし上限あり）
  score += Math.min(slot.durationHours * 1.5, 15);

  // (d) 曜日スコア (最大15点)
  const dayOfWeek = slot.date.getDay();
  if (dayOfWeek === 0 || dayOfWeek === 6) {
    score += 15; // 土日 → ボーナス
  } else if (dayOfWeek === 5) {
    score += 10; // 金曜 → やや高め
  } else {
    score += 5;  // 平日
  }

  // (e) 近さボーナス (最大10点)
  // 直近の方が行動に移しやすい
  const daysFromNow = differenceInDays(slot.date, today());
  if (daysFromNow <= 3) {
    score += 10;
  } else if (daysFromNow <= 7) {
    score += 7;
  } else if (daysFromNow <= 14) {
    score += 4;
  } else {
    score += 1;
  }

  return Math.round(score * 100) / 100; // 小数第2位まで
}
```

### スコアリング配分まとめ

| 要素 | 最大点数 | 説明 |
|------|---------|------|
| 参加率 | 40点 | 全員参加で最大 |
| 天気 | 20点 | 晴れで最大、雨で低下 |
| 時間の長さ | 15点 | 長いほど高い（10時間で上限） |
| 曜日 | 15点 | 土日 > 金曜 > 平日 |
| 直近ボーナス | 10点 | 3日以内が最高 |
| **合計** | **100点** | |

---

## 5. セキュリティ設計

### 5.1 認証 (Authentication)

```
┌──────────┐     ┌──────────┐     ┌──────────────┐
│ iOS App  │────>│ API      │────>│ Apple/LINE   │
│          │     │ Server   │     │ ID Provider  │
│          │<────│          │<────│              │
│          │     │          │     └──────────────┘
│          │     │          │
│ JWT保存  │<────│ JWT発行  │
│ (Keychain)│    │          │
└──────────┘     └──────────┘
```

- **OAuth 2.0 + OpenID Connect**: Apple Sign In / LINE Login の id_token を検証
- **JWT (JSON Web Token)**:
  - Access Token: 有効期限 1時間、署名アルゴリズム RS256
  - Refresh Token: 有効期限 30日、1回使用で無効化（ローテーション）
  - ペイロード: `{ sub: userId, iat, exp, groups: [groupId...] }`
- **トークン保存**: iOS Keychain（暗号化ストレージ）
- **セッション管理**: Redis にリフレッシュトークンのホワイトリストを保持

### 5.2 認可 (Authorization)

```typescript
// ミドルウェアレベルの認可チェック

// グループメンバーのみがグループリソースにアクセス可能
async function requireGroupMember(req, res, next) {
  const userId = req.auth.userId;
  const groupId = req.params.groupId;

  const membership = await GroupMember.findOne({ groupId, userId });
  if (!membership) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'グループメンバーではありません' }
    });
  }

  req.membership = membership;
  next();
}

// 管理者権限チェック
async function requireGroupAdmin(req, res, next) {
  if (!['owner', 'admin'].includes(req.membership.role)) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: '管理者権限が必要です' }
    });
  }
  next();
}

// スケジュールの公開範囲フィルタ
function filterByVisibility(schedules, requesterId, groupMembers) {
  return schedules.filter(schedule => {
    if (schedule.userId === requesterId) return true;        // 自分のは常に見える
    if (schedule.visibility === 'public') return true;       // 公開
    if (schedule.visibility === 'friends') {                 // 友達限定
      return groupMembers.includes(schedule.userId);
    }
    return false; // 'private' は本人のみ
  });
}
```

### 5.3 データ保護

| 対象 | 方法 |
|------|------|
| 通信 | TLS 1.3 (HTTPS / WSS) |
| DB保存 | PostgreSQL の AES-256 透過暗号化 |
| iOS ローカル | Core Data + NSFileProtectionComplete |
| JWT | RS256 署名 + 定期的な鍵ローテーション |
| パスワード | N/A（外部認証のみ、パスワード保存なし） |
| デバイストークン | 暗号化して保存 |

### 5.4 プライバシー制御

```typescript
// ユーザーのプライバシー設定
interface PrivacySettings {
  // 各スケジュールごとに設定可能
  defaultVisibility: 'public' | 'friends' | 'private';

  // スケジュール詳細の公開レベル
  //  - 'full': タイトル・時間・メモ全て公開
  //  - 'busy_only': 「予定あり」とだけ表示（詳細は非公開）
  //  - 'hidden': 完全に非表示
  detailLevel: 'full' | 'busy_only' | 'hidden';
}

// 'busy_only' の場合のレスポンス変換
function sanitizeScheduleForBusyOnly(schedule) {
  return {
    id: schedule.id,
    schedule_type: 'blocked',
    title: '予定あり',        // タイトルを隠す
    start_time: schedule.start_time,
    end_time: schedule.end_time,
    is_all_day: schedule.is_all_day,
    color: '#9E9E9E',        // グレーで表示
    memo: null                // メモを隠す
  };
}
```

### 5.5 API セキュリティ

- **レートリミット**: 認証済み 100 req/min、未認証 20 req/min
- **入力バリデーション**: Zod / Joi でリクエストボディを厳密に検証
- **SQL インジェクション対策**: ORM (Prisma / TypeORM) でパラメータ化クエリ
- **CORS**: iOS アプリからのリクエストのみ許可（API キー検証）
- **招待コード**: ブルートフォース対策としてレートリミット + 一定回数失敗でロック

---

## 6. リアルタイム同期の設計

### 6.1 技術選定: WebSocket (Socket.IO)

| 方式 | 採用 | 理由 |
|------|-----|------|
| WebSocket (Socket.IO) | **採用** | 双方向通信、自動再接続、Room機能 |
| Server-Sent Events | 不採用 | 単方向のみ、iOS での制約あり |
| Polling | フォールバック | WebSocket 不可時のみ |

### 6.2 同期対象データ

| データ | リアルタイム同期 | 理由 |
|--------|----------------|------|
| グループメンバーのスケジュール変更 | **する** | コア機能。変更を即座に反映 |
| 候補日提案の更新 | **する** | スケジュール変更で再計算後に配信 |
| グループメンバーの参加・脱退 | **する** | メンバー変更は即座に反映 |
| 天気情報の更新 | **しない** | 3時間ごとの定期更新で十分 |
| 通知 | **する** | 即座にバッジ更新 |

### 6.3 WebSocket アーキテクチャ

```
┌─────────┐  WSS  ┌─────────────┐  Redis Pub/Sub  ┌─────────────┐
│ iOS App │ ────> │ WS Server 1 │ <────────────> │ WS Server 2 │
│ (User A)│       │             │                │             │
└─────────┘       └─────────────┘                └─────────────┘
                        │                              │
                        └──────────┬───────────────────┘
                                   │
                              ┌────▼─────┐
                              │  Redis   │
                              │ Pub/Sub  │
                              └──────────┘
```

### 6.4 イベント設計

```typescript
// ── サーバー → クライアント イベント ─────────────────

// グループメンバーのスケジュールが変更された
interface ScheduleUpdatedEvent {
  event: 'schedule:updated';
  data: {
    groupId: string;
    userId: string;
    displayName: string;
    action: 'created' | 'updated' | 'deleted';
    schedule: Schedule;   // 変更されたスケジュール
  };
}

// 候補日提案が再計算された
interface SuggestionsRefreshedEvent {
  event: 'suggestions:refreshed';
  data: {
    groupId: string;
    suggestions: Suggestion[];  // 新しい候補日リスト
    reason: string;             // 'schedule_changed' | 'weather_updated' | 'member_changed'
  };
}

// グループメンバーの変更
interface MemberChangedEvent {
  event: 'group:member_changed';
  data: {
    groupId: string;
    action: 'joined' | 'left' | 'removed';
    user: { id: string; displayName: string; avatarUrl: string };
  };
}

// 通知
interface NotificationEvent {
  event: 'notification:new';
  data: {
    notification: Notification;
  };
}

// ── クライアント → サーバー イベント ─────────────────

// グループルームに参加（認証後に送信）
interface JoinGroupEvent {
  event: 'group:join';
  data: {
    groupId: string;
  };
}

// グループルームから退出
interface LeaveGroupEvent {
  event: 'group:leave';
  data: {
    groupId: string;
  };
}
```

### 6.5 Socket.IO Room 設計

```typescript
// WebSocket 接続時の処理
io.on('connection', async (socket) => {
  // JWT 検証
  const user = await authenticateSocket(socket.handshake.auth.token);
  if (!user) {
    socket.disconnect();
    return;
  }

  // ユーザー固有のルームに参加（通知配信用）
  socket.join(`user:${user.id}`);

  // グループルームへの参加リクエスト
  socket.on('group:join', async ({ groupId }) => {
    // メンバーシップ検証
    const isMember = await verifyGroupMembership(user.id, groupId);
    if (isMember) {
      socket.join(`group:${groupId}`);
    }
  });

  socket.on('group:leave', ({ groupId }) => {
    socket.leave(`group:${groupId}`);
  });
});

// スケジュール更新時の配信ロジック
async function onScheduleUpdated(userId: string, schedule: Schedule) {
  // ユーザーが所属する全グループに配信
  const groups = await getUserGroups(userId);

  for (const group of groups) {
    // Redis Pub/Sub 経由で全 WS サーバーに配信
    await redis.publish(`group:${group.id}`, JSON.stringify({
      event: 'schedule:updated',
      data: {
        groupId: group.id,
        userId,
        action: 'updated',
        schedule: filterByVisibility(schedule, group.id)
      }
    }));

    // 候補日の再計算をキューに投入
    await suggestionQueue.add('recalculate', {
      groupId: group.id,
      trigger: 'schedule_changed',
      triggeredBy: userId
    });
  }
}
```

### 6.6 オフライン対応

```typescript
// iOS側: オフライン時の動作
class ScheduleSyncManager {
  // オフライン中の変更をローカルキューに保存
  private pendingChanges: ScheduleChange[] = [];

  func onScheduleChanged(change: ScheduleChange) {
    if (isOnline) {
      // オンライン → 即座にAPI送信
      api.updateSchedule(change);
    } else {
      // オフライン → ローカルキューに保存
      pendingChanges.append(change);
      coreData.save(change); // 永続化
    }
  }

  func onReconnected() {
    // 再接続時にキューをフラッシュ
    for (const change of pendingChanges) {
      api.updateSchedule(change);
    }
    pendingChanges = [];

    // サーバーから最新状態を取得して同期
    api.getSchedules(lastSyncTimestamp);
  }
}
```

---

## 7. バックグラウンド処理設計

### ジョブキュー (Bull Queue)

| ジョブ | トリガー | 処理 |
|--------|---------|------|
| `suggestion:recalculate` | スケジュール変更時 | 候補日提案を再計算し、WebSocket で配信 |
| `weather:fetch` | 3時間ごと (CRON) | OpenWeatherMap API から天気情報を取得してキャッシュ |
| `weather:cleanup` | 1日1回 | 期限切れの天気キャッシュを削除 |
| `notification:push` | 通知作成時 | APNs 経由でプッシュ通知を送信 |
| `suggestion:expire` | 1時間ごと | 期限切れの候補日提案を 'expired' に更新 |

---

## 付録: API エンドポイント一覧

| Method | Endpoint | 説明 | 認証 |
|--------|----------|------|------|
| POST | `/v1/auth/login` | ログイン | No |
| POST | `/v1/auth/register` | 新規登録 | No |
| POST | `/v1/auth/refresh` | トークンリフレッシュ | No |
| GET | `/v1/users/me` | 自分の情報取得 | Yes |
| PUT | `/v1/users/me` | 自分の情報更新 | Yes |
| POST | `/v1/groups` | グループ作成 | Yes |
| GET | `/v1/groups` | グループ一覧 | Yes |
| GET | `/v1/groups/:id` | グループ詳細 | Yes (Member) |
| PUT | `/v1/groups/:id` | グループ更新 | Yes (Admin) |
| DELETE | `/v1/groups/:id` | グループ削除 | Yes (Owner) |
| POST | `/v1/groups/:id/join` | グループ参加 | Yes |
| DELETE | `/v1/groups/:id/members/:userId` | メンバー削除/脱退 | Yes (Admin/Self) |
| POST | `/v1/schedules` | スケジュール登録 | Yes |
| POST | `/v1/schedules/bulk` | スケジュール一括登録 | Yes |
| GET | `/v1/schedules` | 自分のスケジュール取得 | Yes |
| GET | `/v1/groups/:id/schedules` | グループスケジュール取得 | Yes (Member) |
| PUT | `/v1/schedules/:id` | スケジュール更新 | Yes (Owner) |
| DELETE | `/v1/schedules/:id` | スケジュール削除 | Yes (Owner) |
| POST | `/v1/shift-patterns` | シフトパターン作成 | Yes |
| GET | `/v1/shift-patterns` | シフトパターン一覧 | Yes |
| POST | `/v1/shift-patterns/:id/apply` | シフトパターン適用 | Yes |
| GET | `/v1/groups/:id/suggestions` | 候補日提案取得 | Yes (Member) |
| POST | `/v1/groups/:id/suggestions/:sid/respond` | 提案への応答 | Yes (Member) |
| GET | `/v1/weather` | 天気予報取得 | Yes |
| GET | `/v1/notifications` | 通知一覧 | Yes |
| PUT | `/v1/notifications/:id/read` | 通知既読 | Yes |
