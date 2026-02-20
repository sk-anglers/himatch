# Himatch（ヒマッチ） 詳細仕様書

**バージョン**: 1.0
**最終更新日**: 2026-02-20
**対象**: Flutter クライアントアプリケーション

---

## 1. 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|----------|
| フレームワーク | Flutter | 3.41.1 |
| 言語 | Dart | 3.11.0 |
| 状態管理 | Riverpod | 3.x |
| ルーティング | go_router | 17.x |
| カレンダー | table_calendar | 3.x |
| アニメーション | flutter_animate | 4.x |
| データモデル | Freezed + json_serializable | — |
| バックエンド | Supabase (PostgreSQL 16) | — |
| 天気 API | Open-Meteo | 無料 |
| 位置情報 | geolocator | — |
| 認証 | Supabase Auth | Apple / Google / LINE |
| プッシュ通知 | FCM | — |

---

## 2. アプリケーション構成

### 2.1 ディレクトリ構造

```
lib/
├── main.dart                     # エントリーポイント
├── app.dart                      # MaterialApp.router 定義
├── core/
│   ├── constants/
│   │   ├── app_constants.dart    # API URL, デフォルト座標, ユーザー ID
│   │   ├── app_spacing.dart      # レイアウト定数
│   │   └── demo_data.dart        # デモモード用初期データ
│   ├── theme/
│   │   ├── app_theme.dart        # テーマ定義 (Light/Dark, 6 プリセット)
│   │   └── app_colors_extension.dart  # テーマカラー拡張
│   ├── utils/
│   │   └── date_utils.dart       # 日付フォーマットユーティリティ
│   └── widgets/
│       ├── empty_state_widget.dart    # 空状態共通 UI
│       └── skeleton_loader.dart       # ローディング UI
├── models/                       # Freezed データモデル（20 種類）
├── providers/                    # グローバル Riverpod プロバイダー
├── routing/
│   ├── app_router.dart           # GoRouter ルート定義
│   └── app_routes.dart           # ルート名 enum
├── services/                     # 外部サービス統合
└── features/                     # 機能別モジュール
    ├── auth/
    ├── home/
    ├── schedule/
    ├── suggestion/
    ├── group/
    ├── chat/
    ├── booking/
    ├── expense/
    ├── shift/
    ├── profile/
    ├── history/
    └── wellbeing/
```

### 2.2 feature モジュール構造（共通パターン）

```
features/<feature>/
├── domain/           # ビジネスロジック・エンジン
├── presentation/
│   ├── <screen>.dart           # 画面ウィジェット
│   ├── providers/              # feature 固有の Riverpod プロバイダー
│   └── widgets/                # feature 固有のウィジェット
└── data/             # リポジトリ・データソース（将来用）
```

---

## 3. 画面一覧・ルーティング

### 3.1 ホーム画面（タブ構成）

| タブ | パス | ウィジェット | 説明 |
|------|------|------------|------|
| カレンダー | `/` (tab 0) | `CalendarTab` | 月カレンダー + シフトペイント + インライン予定表示 |
| 提案 | `/` (tab 1) | `SuggestionsTab` | グループフィルター + 候補カレンダー + 詳細シート |
| グループ | `/` (tab 2) | `GroupsTab` | グループ一覧 + 作成 FAB + 招待コード参加 |
| マイページ | `/` (tab 3) | `ProfileTab` | ユーザー情報 + 設定リンク |

### 3.2 全ルート定義

| パス | 画面 | 遷移方式 | パラメーター |
|------|------|---------|------------|
| `/` | HomeScreen | — | — |
| `/login` | LoginScreen | FadeThrough | — |
| `/schedule/new` | ScheduleFormScreen | SlideUp 400ms | — |
| `/schedule/calendar-sync` | CalendarSyncSettingsScreen | FadeThrough | — |
| `/schedule/templates` | TemplateScreen | FadeThrough | — |
| `/group/:groupId` | GroupDetailScreen | FadeThrough | groupId, extra: group |
| `/group/:groupId/calendar` | GroupCalendarScreen | FadeThrough | groupId, extra: group |
| `/group/:groupId/shift-calendar` | ShiftListCalendarScreen | FadeThrough | groupId, extra: group |
| `/group/:groupId/chat` | ChatScreen | FadeThrough | groupId, extra: groupId, groupName, memberCount |
| `/group/:groupId/poll` | PollScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/board` | BoardScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/todo` | TodoListScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/album` | AlbumScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/activity` | ActivityFeedScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/expense` | ExpenseScreen | FadeThrough | groupId, extra: groupId, groupName |
| `/group/:groupId/settlement` | SettlementScreen | FadeThrough | groupId |
| `/booking` | BookingScreen | FadeThrough | — |
| `/share-card` | ShareCardScreen | FadeThrough | extra: date, activity, groupName, weather |
| `/public-vote` | PublicVoteScreen | FadeThrough | — |
| `/shift/workplace-settings` | WorkplaceSettingsScreen | FadeThrough | — |
| `/shift/salary-summary` | SalarySummaryScreen | FadeThrough | — |
| `/shift/patterns` | ShiftPatternScreen | FadeThrough | — |
| `/settings/weather-location` | WeatherLocationScreen | FadeThrough | — |
| `/settings/theme` | ThemeSettingsScreen | FadeThrough | — |
| `/settings/notifications` | NotificationSettingsScreen | FadeThrough | — |
| `/settings/terms` | TermsOfServiceScreen | FadeThrough | — |
| `/settings/privacy` | PrivacyPolicyScreen | FadeThrough | — |
| `/settings/contact` | ContactScreen | FadeThrough | — |
| `/history` | HistoryScreen | FadeThrough | — |
| `/wellbeing` | WellbeingScreen | FadeThrough | — |

---

## 4. データモデル仕様

### 4.1 コアモデル

#### AppUser
```dart
@freezed class AppUser {
  String id;                  // UUID
  String? displayName;        // 表示名
  String? email;
  String? avatarUrl;
  String authProvider;        // 'apple' | 'google' | 'line' | 'demo'
  String? authProviderId;
  String? deviceToken;        // FCM トークン
  String timezone;            // デフォルト 'Asia/Tokyo'
  String privacyDefault;      // 'friends' | 'public' | 'private'
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

#### Group
```dart
@freezed class Group {
  String id;                  // UUID
  String name;                // グループ名（100文字以内）
  String? description;        // 説明（500文字以内）
  String? iconUrl;
  String inviteCode;          // 8桁英数字（自動生成）
  DateTime? inviteCodeExpiresAt;
  String createdBy;           // 作成者 userId
  int maxMembers;             // デフォルト 20
  String? colorHex;           // グループカラー（例: 'FF3498DB'）
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

**groupColor() ヘルパー**: `colorHex` が設定されていればその色を返す。未設定の場合、グループ名の hashCode から 8 色パレットを自動割り当て。

**groupColorOptions**: 8色プリセット
- `FF3498DB`(青), `FFF39C12`(橙), `FF00B894`(緑), `FFE84393`(桃), `FF6C5CE7`(紫), `FFE17055`(赤), `FF0984E3`(海), `FF636E72`(灰)

#### GroupMember
```dart
@freezed class GroupMember {
  String id;
  String groupId;
  String userId;
  String role;                // 'owner' | 'admin' | 'member'
  String? nickname;
  DateTime? joinedAt;
}
```

#### Schedule
```dart
@freezed class Schedule {
  String id;
  String userId;
  String title;
  String? description;
  ScheduleType scheduleType;  // shift | event | free | blocked
  DateTime startTime;
  DateTime endTime;
  bool isAllDay;
  String? recurrenceRule;     // iCalendar RRULE 形式
  String visibility;          // 'public' | 'friends' | 'private'
  String? color;              // カスタムカラー
  String? workplaceId;        // シフトの場合の勤務先紐付け
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

#### Suggestion
```dart
@freezed class Suggestion {
  String id;
  String groupId;
  DateTime suggestedDate;
  String timeCategory;        // 'morning' | 'lunch' | 'afternoon' | 'evening' | 'all_day'
  String activityType;        // 'ランチ' | '飲み会' | '日帰り旅行' 等
  DateTime startTime;
  DateTime endTime;
  double durationHours;
  List<String> availableMembers;  // 参加可能メンバーの userId リスト
  int totalMembers;
  double availabilityRatio;   // 参加率 (0.0〜1.0)
  WeatherSummary? weatherSummary;
  double score;               // 0〜1.0（100点満点を正規化）
  SuggestionStatus status;    // proposed | confirmed | dismissed
}
```

#### WeatherSummary（Suggestion に内包）
```dart
@freezed class WeatherSummary {
  String condition;           // '快晴' | '曇り' | '雨' 等
  String? icon;               // '☀️' | '🌧️' 等
  double? tempHigh;
  double? tempLow;
  int? humidity;
  double? windSpeed;
  int? rainProbability;
}
```

### 4.2 シフト・給料モデル

#### ShiftType
```dart
@freezed class ShiftType {
  String id;
  String? workplaceId;
  String label;               // '早番' | '遅番' | '夜勤' 等
  String name;                // 表示名
  String color;               // カラーコード
  String? startTime;          // デフォルト開始時刻
  String? endTime;            // デフォルト終了時刻
}
```

#### Workplace
```dart
@freezed class Workplace {
  String id;
  String userId;
  String name;                // 勤務先名
  int hourlyRate;             // 時給（円）
  int transportCost;          // 交通費（円/回）
  int? taxWall103;            // 103万の壁設定
  int? taxWall130;
  int? taxWall150;
}
```

#### SalaryBreakdown（計算結果）
```dart
class SalaryBreakdown {
  int basePay;                // 基本給（時給×時間）
  double totalHours;          // 合計勤務時間
  int transportCost;          // 交通費合計
  int workingDays;            // 出勤日数
  int totalPay;               // 総支給額
}
```

### 4.3 グループ機能モデル

| モデル | 主要フィールド | 用途 |
|--------|-------------|------|
| ChatMessage | id, groupId, userId, displayName, content, imageUrl, createdAt | チャット |
| Poll | id, groupId, question, options, isAnonymous, createdBy, deadline | 投票 |
| Vote (候補日投票) | id, suggestionId, userId, displayName, voteType, votedAt | 候補日投票 |
| Post | id, groupId, userId, content, createdAt | 掲示板 |
| TodoItem | id, groupId, title, assigneeId, dueDate, isCompleted | ToDo |
| Photo | id, groupId, imageUrl, caption, createdBy, createdAt | アルバム |
| Activity | id, groupId, activityType, actorName, description, data, createdAt | フィード |
| Expense | id, groupId, description, amount, paidBy, payerName, category, splitType, participants, createdAt | 割り勘 |

---

## 5. コア機能仕様

### 5.1 候補日提案エンジン

**ファイル**: `lib/features/suggestion/domain/suggestion_engine.dart`

#### 5.1.1 処理フロー

```
[全メンバーのスケジュール取得]
    ↓
[日ごとに空き時間抽出] ← 営業時間 8:00-22:00 内の隙間計算
    ↓
[スイープラインで共通空き検出] ← O(n log n) アルゴリズム
    ↓
[時間帯分類]
    ↓
[天気情報取得] ← Open-Meteo API
    ↓
[アクティビティ提案] ← 時間帯 × 長さ × 天気 ルール
    ↓
[スコアリング] ← 100点満点
    ↓
[ソート・返却]
```

#### 5.1.2 時間帯分類ルール

| 条件 | 分類 | アクティビティ例 |
|------|------|---------------|
| 10h 以上の空き | all_day | 日帰り旅行・テーマパーク |
| 4〜7h の午後空き | afternoon | ショッピング＆ディナー |
| 2〜4h の夜空き | evening | 飲み会・ディナー |
| 1〜2h の昼空き | lunch | ランチ・カフェ |
| 1〜3h の午前空き | morning | モーニング・ブランチ |

#### 5.1.3 天気×アクティビティマッピング

| 天気 | 時間帯 | 提案 |
|------|--------|------|
| 晴れ (25℃+) | all_day | BBQ・ビアガーデン・プール |
| 晴れ (15-24℃) | all_day | ピクニック・テーマパーク |
| 晴れ (〜14℃) | evening | 温泉・鍋パーティー |
| 曇り | afternoon | ショッピング・カフェ巡り |
| 雨 | evening | 映画・ボウリング・カラオケ |
| 雪 | all_day | スキー・スノボ・温泉 |

#### 5.1.4 スコアリング配分（100点満点）

| 要素 | 配点 | 計算方法 |
|------|------|---------|
| 参加率 | 40点 | `(参加人数/全人数) × 40` |
| 天気 | 20点 | 晴れ=20, 曇り=15, 雨=5 |
| 時間の長さ | 15点 | `min(durationHours / 10, 1) × 15` |
| 曜日 | 15点 | 土日=15, 金=10, 平日=5 |
| 直近ボーナス | 10点 | 3日以内=10, 7日以内=7, それ以降=3 |

### 5.2 カレンダー表示

**ファイル**: `lib/features/schedule/presentation/calendar_tab.dart`

#### 5.2.1 レイアウト構成

```
┌─────────────────────────────────────┐
│ TableCalendar (月表示)               │
│  - rowHeight: 72px                  │
│  - startingDayOfWeek: Monday        │
│  - formatButtonVisible: true        │
│  - 月/2週切替対応                    │
│                                     │
│  ┌─────── BaseCalendarCell ────────┐│
│  │ [日付番号]  ← 祝日:赤 土:青     ││
│  │ [祝日名/天気] ← 中段 (7pt)     ││
│  │ [シフトバッジ] ← 下段 (18px)   ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│ インライン予定表示 (_InlineScheduleTile) │
│  - 選択日の予定をタイル表示           │
│  - 種別アイコン + タイトル + 時間     │
├─────────────────────────────────────┤
│ シフトペイントパネル (_ShiftPaintPanel) │
│  - アクセントカラー背景 + ボーダー    │
│  - シフト種別ボタン (Wrap)            │
│  - 「完了」ボタン + 「編集」リンク   │
│  - 両状態で統一 UI（入力中の明示）   │
└─────────────────────────────────────┘
```

#### 5.2.2 シフトペイントモード

1. カレンダー下部の鉛筆アイコン FAB をタップ → ペイントパネル表示
2. シフト種別（早番・遅番・夜勤等）を選択
3. カレンダー上の日付をタップ → その日にシフトがトグル登録/解除
4. 別の種別を選択して続けてタップ可能
5. 「完了」ボタンで入力終了、パネルを閉じる

**UI 仕様**: シフト選択中・未選択の両状態で同一デザイン（アクセントカラー背景 + ボーダー + 「完了」ボタン）。入力モードであることを常時明示。

### 5.3 グループカラーシステム

#### 5.3.1 カラー適用箇所

| 画面 | 適用箇所 | 詳細 |
|------|---------|------|
| グループ一覧 | カード全体 | 背景色(alpha 0.18) + ボーダー(alpha 0.4) |
| グループ一覧 | アバター | 背景色(alpha 0.2) + 頭文字テキスト色 |
| グループ詳細 | InfoCard 全体 | 背景色(alpha 0.18) + ボーダー(alpha 0.4) |
| グループ詳細 | パレットアイコン | タップで色変更ボトムシート |
| 提案タブ | セレクターチップ | 選択時: 塗りつぶし / 非選択時: 薄い背景+ボーダー |
| 提案タブ | 候補タイル全体 | 背景色(alpha 0.14) + ボーダー(alpha 0.4) |
| 提案タブ | グループ名バッジ | 背景色(alpha 0.25) + テキスト色 |

#### 5.3.2 カラー変更フロー

1. グループ詳細画面の InfoCard をタップ
2. ボトムシートで 8 色プリセットから選択
3. `LocalGroupsNotifier.updateGroupColor()` で即座に state 更新
4. Riverpod の watch により全画面に自動反映

### 5.4 投票システム

#### 5.4.1 投票フロー

```
[候補タイル表示]
    ↓
[OK / 微妙 / NG ボタン]
    ├── 未投票 → 白背景ボタン（各色ボーダー+テキスト）
    ├── 選択中 → 塗りつぶしボタン（白テキスト）
    └── 再タップ → 投票解除（トグル動作）
    ↓
[投票サマリー表示] ← リアルタイム更新
    ↓
[オーナーのみ「決定」ボタン表示]
    ↓
[確定 → カレンダーに自動追加]
```

#### 5.4.2 トグル動作仕様

`castVote()` メソッド: 同一ユーザーが同一 VoteType で再投票した場合、投票を削除（トグル OFF）。異なる VoteType の場合は上書き。

### 5.5 天気予報統合

#### 5.5.1 データソース
- **API**: Open-Meteo (https://api.open-meteo.com)
- **データ元**: JMA（気象庁）
- **精度**: 3日以内 高精度 / 7日以内 中精度 / 14日先まで低精度

#### 5.5.2 地域設定

| モード | 説明 | デフォルト |
|--------|------|----------|
| GPS | 端末の位置情報から自動取得 | — |
| 都市名検索 | Open-Meteo Geocoding API で検索・選択 | — |
| デモモード | 福岡市 (33.59°N, 130.40°E) | ○ |
| フォールバック | 東京 (35.68°N, 139.69°E) | GPS 失敗時 |

**GPS トグル仕様**: 「現在地を使う」ボタンは ON/OFF のトグル動作。ON 状態で再タップすると解除し、デフォルト（東京）に戻る。

#### 5.5.3 WMO 天気コード → 日本語マッピング

| コード | 条件 | アイコン |
|--------|------|---------|
| 0 | 快晴 | ☀️ |
| 1-3 | 晴れ/曇り | 🌤️ / ⛅ / ☁️ |
| 45-48 | 霧 | 🌫️ |
| 51-55 | 霧雨 | 🌧️ |
| 61-65 | 雨 | 🌧️ |
| 71-77 | 雪 | 🌨️ / ❄️ |
| 80-82 | にわか雨 | 🌦️ |
| 95-99 | 雷雨 | ⛈️ |

### 5.6 給料計算

#### 5.6.1 計算式

```
基本給 = Σ(各シフトの勤務時間 × 時給)
交通費 = 出勤日数 × 1回あたりの交通費
総支給額 = 基本給 + 交通費
```

#### 5.6.2 税壁警告

| 壁 | 年収基準 | 影響 |
|----|---------|------|
| 103万の壁 | 1,030,000円 | 所得税発生 |
| 130万の壁 | 1,300,000円 | 社会保険料発生 |
| 150万の壁 | 1,500,000円 | 配偶者控除額減少 |

年間見込み = 当月給料 × 12 で概算し、各壁に接近している場合に警告を表示。

---

## 6. データベーススキーマ

### 6.1 テーブル定義（Supabase PostgreSQL）

```sql
-- ユーザー
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name    VARCHAR(50),
    email           VARCHAR(255),
    avatar_url      VARCHAR(500),
    auth_provider   VARCHAR(20) NOT NULL,        -- apple | google | line
    auth_provider_id VARCHAR(255),
    device_token    VARCHAR(500),                -- FCM トークン
    timezone        VARCHAR(50) DEFAULT 'Asia/Tokyo',
    privacy_default VARCHAR(20) DEFAULT 'friends',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- グループ
CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(500),
    icon_url        VARCHAR(500),
    invite_code     VARCHAR(20) UNIQUE NOT NULL,
    invite_code_expires_at TIMESTAMPTZ,
    created_by      UUID NOT NULL REFERENCES users(id),
    max_members     INT NOT NULL DEFAULT 20,
    color_hex       VARCHAR(10),                 -- グループカラー
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- グループメンバー
CREATE TABLE group_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id    UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id),
    role        VARCHAR(20) NOT NULL DEFAULT 'member',  -- owner | admin | member
    nickname    VARCHAR(50),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- スケジュール
CREATE TABLE schedules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    schedule_type   VARCHAR(20) NOT NULL,        -- shift | event | free | blocked
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule VARCHAR(255),                -- iCalendar RRULE
    visibility      VARCHAR(20) NOT NULL DEFAULT 'friends',
    color           VARCHAR(20),
    workplace_id    UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- スケジュール高速検索用 GiST インデックス
CREATE INDEX idx_schedules_time_range
    ON schedules USING GiST (tstzrange(start_time, end_time));

-- 候補日提案
CREATE TABLE suggestions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id            UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    suggested_date      DATE NOT NULL,
    time_category       VARCHAR(20) NOT NULL,
    activity_type       VARCHAR(100) NOT NULL,
    start_time          TIMESTAMPTZ NOT NULL,
    end_time            TIMESTAMPTZ NOT NULL,
    available_members   UUID[] NOT NULL,
    total_members       INT NOT NULL,
    availability_ratio  DECIMAL(3,2) NOT NULL,
    weather_summary     JSONB,
    score               DECIMAL(5,4) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'proposed',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 天気キャッシュ
CREATE TABLE weather_cache (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_key    VARCHAR(50) NOT NULL,
    forecast_date   DATE NOT NULL,
    condition       VARCHAR(50),
    icon            VARCHAR(10),
    temp_high       DECIMAL(4,1),
    temp_low        DECIMAL(4,1),
    humidity        INT,
    wind_speed      DECIMAL(4,1),
    rain_probability INT,
    expires_at      TIMESTAMPTZ NOT NULL,
    UNIQUE(location_key, forecast_date)
);
```

### 6.2 RLS ポリシー

| テーブル | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| users | 本人のみ | Supabase Auth | 本人のみ | — |
| schedules | 本人 or グループメンバー(visibility準拠) | 本人 | 本人 | 本人 |
| groups | メンバーのみ | 認証済み | オーナー/管理者 | オーナー |
| group_members | 同グループメンバー | グループオーナー | グループオーナー | 本人(退出) or オーナー |
| suggestions | グループメンバー | システム | グループオーナー(確定) | — |

---

## 7. サービス層仕様

### 7.1 WeatherService

| メソッド | 引数 | 返却値 | 説明 |
|---------|------|--------|------|
| `fetchForecast` | lat, lon, days | `List<DailyForecast>` | Open-Meteo API から天気予報取得 |

- **キャッシュ**: メモリ内 1 時間。座標変更時に無効化
- **フォールバック**: API 失敗時は空リスト返却（候補日スコアの天気配点を 0 に）

### 7.2 GeocodingService

| メソッド | 引数 | 返却値 | 説明 |
|---------|------|--------|------|
| `search` | query | `List<GeocodingResult>` | 都市名で緯度経度を検索 |

### 7.3 SalaryCalculator

| メソッド | 引数 | 返却値 | 説明 |
|---------|------|--------|------|
| `calculate` | shifts, workplace, month | `SalaryBreakdown` | 月間給料計算 |

### 7.4 HolidayService

| メソッド | 引数 | 返却値 | 説明 |
|---------|------|--------|------|
| `getHoliday` | date | `String?` | 日本の祝祭日名を返却。該当なしは null |

内蔵データ: 2024〜2030 年の祝日テーブル（振替休日含む）

---

## 8. デザインシステム

### 8.1 カラーパレット

| 名前 | 値 | 用途 |
|------|-----|------|
| primary | `#6C5CE7` | メインアクション |
| primaryLight | `#A29BFE` | サブアクション |
| secondary | `#FD79A8` | アクセント |
| success | `#00B894` | 成功・確定 |
| warning | `#FDCB6E` | 注意 |
| error | `#E17055` | エラー・削除 |
| background | `#F8F9FA` | 画面背景 |
| textPrimary | `#2D3436` | メインテキスト |
| textSecondary | `#636E72` | サブテキスト |
| textHint | `#B2BEC3` | ヒントテキスト |

### 8.2 テーマプリセット（6 色）

| 名前 | seedColor | 説明 |
|------|-----------|------|
| デフォルト | `#6C5CE7` | 紫（ブランドカラー） |
| オーシャン | `#0984E3` | 海青 |
| フォレスト | `#00B894` | 緑 |
| サンセット | `#E17055` | 夕焼け |
| ラベンダー | `#A29BFE` | 薄紫 |
| ローズ | `#FD79A8` | ピンク |

### 8.3 タイポグラフィ

| 用途 | サイズ | ウェイト |
|------|--------|---------|
| 画面タイトル | 28pt | Bold |
| セクション見出し | 20pt | SemiBold |
| カードタイトル | 17pt | SemiBold |
| 本文 | 15pt | Regular |
| 補足・注釈 | 13pt | Regular |
| ラベル | 11pt | Medium |
| カレンダー祝日名 | 7pt | Bold |

### 8.4 アニメーション仕様

| 対象 | 種類 | 時間 | イージング |
|------|------|------|----------|
| ページ遷移（通常） | FadeThrough | 300ms | easeInOut |
| ページ遷移（モーダル） | SlideUp + FadeIn | 400ms | easeOutCubic |
| リストアイテム | fadeIn + slideY(0.1) | 300ms + delay 50ms×index | easeOut |
| カードタップ | scale(0.97→1.0) | 200ms | easeOutBack |
| シフトバッジ | fadeIn + scale | 150ms | easeInOut |

---

## 9. 外部 API 仕様

### 9.1 Open-Meteo Weather API

**エンドポイント**: `https://api.open-meteo.com/v1/forecast`

**パラメーター**:
```
latitude=35.68&longitude=139.69
&daily=weather_code,temperature_2m_max,temperature_2m_min,
       precipitation_probability_max,wind_speed_10m_max
&timezone=Asia/Tokyo
&forecast_days=14
```

**レスポンス**: JSON（daily 配列に日ごとの天気データ）

### 9.2 Open-Meteo Geocoding API

**エンドポイント**: `https://geocoding-api.open-meteo.com/v1/search`

**パラメーター**: `name=大阪&count=5&language=ja`

**レスポンス**: JSON（results 配列に都市名・緯度・経度・国・行政区域）

---

## 10. テスト仕様

### 10.1 テストカバレッジ

| カテゴリ | テスト数 | 内容 |
|---------|---------|------|
| モデル | 20+ | Freezed モデルのシリアライズ・デシリアライズ |
| 提案エンジン | 15+ | スコアリング・時間帯分類・天気マッピング |
| 投票 | 10+ | 投票・トグル・集計 |
| 給料計算 | 5+ | 基本計算・税壁警告 |
| 合計 | 53 | 全テスト合格 |

### 10.2 テスト実行

```bash
flutter test
```

---

## 11. デモモード仕様

### 11.1 概要
Supabase 接続なしで全機能を操作可能。初期データは `DemoData` クラスで定義。

### 11.2 デモデータ

| データ | 内容 |
|--------|------|
| ユーザー | demo-user-local（ローカルユーザー） |
| グループ | ゼミ3年（青）、バイト仲間（橙） |
| メンバー | 各グループに 3〜4 人 |
| スケジュール | 当月の過去・未来に計 15+ 件（シフト中心） |
| 勤務先 | カフェ(¥1050/h), コンビニ(¥1100/h) |
| シフト種別 | 早番(#2196F3), 遅番(#FF9800), 夜勤(#9C27B0) |

### 11.3 デモモード判定
`AuthState.isDemo == true` の場合、全プロバイダーがローカル実装（`Local*Notifier`）を使用。

---

## 12. 既知の制限・今後の課題

| # | 課題 | 優先度 | 対応予定 |
|----|------|--------|---------|
| 1 | Supabase スキーマに `color_hex` カラム未追加 | P1 | Phase 2 マイグレーション |
| 2 | GroupService.createGroup() に colorHex パラメーター未反映 | P1 | Supabase 接続時に対応 |
| 3 | カレンダーアプリ連携（Apple / Google Calendar） | P0 | Phase 2 |
| 4 | リマインダー通知 | P1 | Phase 2 |
| 5 | 画像アップロード（チャット・アルバム） | P1 | Supabase Storage 利用予定 |
| 6 | リアルタイム同期（チャット・投票） | P0 | Supabase Realtime |
| 7 | Deep Link（招待コードからの直接参加） | P1 | go_router のリダイレクト機能 |
