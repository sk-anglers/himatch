# Himatch 技術選定 最終決定書

## 最終スタック

| レイヤー | 技術 | 決定理由 |
|---------|------|---------|
| **フロントエンド** | **Flutter (Dart)** | カスタムUI自由度、将来Android対応、Hot Reload |
| **バックエンド** | **Supabase (PostgreSQL)** | 候補日提案エンジンにSQL必須、コスト予測可能、OSS |
| **データベース** | **PostgreSQL 16** (Supabase内包) | GiST索引でtstzrange検索、外部キー制約 |
| **リアルタイム同期** | **Supabase Realtime** | PostgreSQL WALベースの変更通知 |
| **オフラインキャッシュ** | **Drift (SQLite)** | Flutter用SQLiteラッパー、ローカルキャッシュ |
| **認証** | **Supabase Auth** + LINE Login | Apple/Google標準対応、LINEはカスタムOAuth |
| **プッシュ通知** | **FCM (Firebase Cloud Messaging)** | Supabaseと独立利用可、無料無制限 |
| **天気API** | **Open-Meteo** (Phase 2) | JMA気象庁データ直接利用、日本最高精度、無料 |
| **状態管理** | **Riverpod** | Flutter標準的、型安全、テスタブル |
| **ルーティング** | **go_router** | 宣言的ルーティング、ディープリンク対応 |
| **CI/CD** | **GitHub Actions + Fastlane** | 自動ビルド、App Store配信 |

---

## 決定の根拠

### 1. フロントエンド: Flutter（全員一致）

両提案とも Flutter を推奨。React Native は次点だが、以下で Flutter が優位：

- **カードUI**: Tinder的スワイプの候補日カードは Flutter の独自レンダリングが最適
- **カレンダーUI**: table_calendar パッケージが成熟、カスタマイズ性高い
- **将来Android対応**: Phase 3で同一コードベース展開可能
- **パフォーマンス**: AOTコンパイルでほぼネイティブ性能

### 2. バックエンド: Supabase（Firebase不採用の理由）

**最大の決定要因: 候補日提案アルゴリズムにSQLが必須**

Himatchのコア機能「文脈付き候補日提案」は以下のクエリを必要とする：

```sql
-- グループ全員の空き時間を重ね合わせて共通空き時間を検出
SELECT
  date_trunc('day', s.start_time) AS candidate_date,
  MAX(s.start_time) AS common_start,
  MIN(s.end_time) AS common_end,
  COUNT(DISTINCT s.user_id) AS available_count
FROM schedules s
JOIN group_members gm ON s.user_id = gm.user_id
WHERE gm.group_id = :group_id
  AND s.schedule_type = 'free'
  AND tstzrange(s.start_time, s.end_time) &&
      tstzrange(:search_start, :search_end)
GROUP BY date_trunc('day', s.start_time)
HAVING COUNT(DISTINCT s.user_id) >= :min_members
ORDER BY available_count DESC, candidate_date ASC;
```

**Firestoreではこれが不可能：**
- JOINなし → メンバーのスケジュールを個別取得してクライアントorCloud Functionsで結合が必要
- tstzrange / OVERLAPS / GiSTインデックスなし → 時間範囲の重なり検出が非効率
- GROUP BY + HAVING なし → 集計はアプリケーション層で実装

**Supabaseなら：**
- architecture.md のスキーマ（GiSTインデックス付き）をそのまま適用可能
- Row Level Security (RLS) でグループメンバーのみデータアクセスを制御
- Edge Functions で提案ロジックを実装

### 3. リアルタイム同期: Supabase Realtime

- PostgreSQLのWAL（Write-Ahead Log）ベースで変更通知を配信
- `supabase_flutter` パッケージで `.stream()` API利用可能
- スケジュール変更 → 自動で候補日再計算 → リアルタイム通知

Firebase Realtimeの方が成熟しているが、Himatchは「チャットアプリ」ではなく「スケジュール更新の反映」が主用途。Supabase Realtimeで十分。

### 4. オフライン対応: Drift (SQLite)

Firebase最大の利点「オフライン自動キャッシュ」の代替として：

- **Drift**: Flutter用SQLite ORM。ローカルにスケジュールをキャッシュ
- オフライン時の操作をキューに保存、オンライン復帰時に同期
- Firestoreほど透過的ではないが、実装コストは2-3日程度

### 5. コスト比較（修正済み）

| 規模 | DAU | Firestore | Supabase Pro | 判定 |
|------|-----|-----------|-------------|------|
| MVP | 100 | $0 | $0 (Free) | 同等 |
| 初期成長 | 1,000 | ~$2 | $25 | Firestore安い |
| 成長期 | 5,000 | ~$8-50※ | $25 | 同等～Supabase有利 |
| スケール | 10,000 | ~$15-100※ | $25 | Supabase有利 |

※Firestoreはリアルタイムリスナー再接続時の再読取で予測困難。Supabaseは固定。

**コストは決定要因ではない。SQLの必要性が最大の理由。**

---

## 非採用技術と理由

| 技術 | 不採用理由 |
|------|----------|
| React Native | Flutter のカスタムUI自由度が候補日カードUIに最適 |
| SwiftUI | Android対応不可（Phase 3のコスト増大） |
| Firebase/Firestore | NoSQLでは候補日提案の集計クエリが困難 |
| MongoDB | 同上。リレーショナルデータに不向き |
| WeatherAPI.com | Open-MeteoがJMA精度で日本市場に最適、かつ無料 |
| Apple WeatherKit | JWT認証が複雑。Open-Meteoで十分 |

---

## パッケージ構成 (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.x       # Supabase Flutter SDK

  # 認証
  sign_in_with_apple: ^6.x     # Apple Sign In
  flutter_line_sdk: ^3.x       # LINE Login (公式SDK)
  google_sign_in: ^6.x         # Google Sign In

  # ローカルDB（オフライン対応）
  drift: ^2.x                  # SQLite ORM
  sqlite3_flutter_libs: ^0.x   # SQLite ネイティブライブラリ

  # 通知
  firebase_core: ^3.x          # FCM用（Firebase Auth不使用）
  firebase_messaging: ^15.x    # プッシュ通知

  # UI
  table_calendar: ^3.x         # カレンダーUI
  flutter_riverpod: ^2.x       # 状態管理
  go_router: ^14.x             # ルーティング

  # ユーティリティ
  intl: ^0.19.x                # 日付フォーマット（日本語対応）
  share_plus: ^9.x             # 招待リンク共有（Share Sheet）
  qr_flutter: ^4.x             # QRコード生成
  mobile_scanner: ^5.x         # QRコードスキャン
  flutter_animate: ^4.x        # アニメーション
  cached_network_image: ^3.x   # 画像キャッシュ

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.x           # Drift コード生成
  drift_dev: ^2.x              # Drift コード生成
  flutter_lints: ^4.x          # Lint ルール
  mockito: ^5.x                # テスト用モック
```

---

## 初期コスト見積もり

| 項目 | 月額 |
|------|------|
| Supabase Free | $0 |
| Apple Developer Program | $8.25/月 ($99/年) |
| FCM | $0 |
| Open-Meteo | $0 |
| GitHub Free | $0 |
| **合計** | **約 $8/月（約1,200円）** |

リリース後 Supabase Pro に移行: **+$25/月 → 合計約 $33/月（約5,000円）**

---

## architecture.md との整合性

| architecture.md の設計 | 本決定での対応 |
|----------------------|-------------|
| Node.js + Express (TypeScript) | → Supabase Edge Functions (TypeScript/Deno) |
| PostgreSQL 16 | → Supabase内包のPostgreSQL（スキーマそのまま適用） |
| Socket.IO + Redis Pub/Sub | → Supabase Realtime（PostgreSQL WALベース） |
| JWT + OAuth 2.0 | → Supabase Auth（JWT自動管理） |
| Bull Queue (Redis) | → Supabase Edge Functions + pg_cron |
| APNs | → FCM（APNs自動ラップ） |
| Swift / SwiftUI | → Flutter (Dart) |

**DBスキーマ（8テーブル）とAPI設計（22エンドポイント）はそのまま活用可能。**

---

*決定日: 2026-02-16*
*決定者: Claude Opus 4.6 + ユーザー承認*
