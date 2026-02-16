# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- プロジェクト設計ドキュメント一式 (MVP機能スコープ、UI/UX設計、システム設計、技術選定)
- 技術選定最終決定: Flutter + Supabase (PostgreSQL)
- CHANGELOG.md (Keep a Changelog 形式)
- CLAUDE.md (プロジェクト固有の開発ルール)
- GitHub Issue ラベル (feature, bug, chore, docs, refactor, test, P0-P2)
- main ブランチ保護ルール (PR必須)
- .gitignore を Flutter/iOS/Android/Supabase 向けに最適化
- Flutter プロジェクト初期化 (Flutter 3.41.1 / Dart 3.11.0)
- Riverpod + go_router によるアプリ基盤 (app.dart, main.dart, app_router.dart)
- デザインシステム: AppTheme / AppColors (Purple #6C5CE7 ベース)
- ホーム画面スキャフォールド (4タブ: カレンダー/提案/グループ/マイページ)
- ログイン画面スキャフォールド (Apple/Google/LINE ボタン配置)
- コア定数・ユーティリティ (AppConstants, AppDateUtils)
- 依存パッケージ: supabase_flutter, table_calendar, flutter_animate, freezed 等
- データモデル (Freezed v3 + json_serializable): AppUser, Group, GroupMember, Schedule, Suggestion, ShiftPattern, AppNotification
- スケジュール種別 (ScheduleType): shift/event/free/blocked
- 文脈分類 (TimeCategory): morning/lunch/afternoon/evening/all_day
- 天気情報モデル (WeatherSummary): 候補日の天気表示用
- モデル単体テスト (10テスト: fromJson/toJson/copyWith/enum)
- Supabase 初期化 (環境変数ベース: SUPABASE_URL, SUPABASE_ANON_KEY)
- AuthService: Apple/Google OAuth サインイン/サインアウト + Riverpod Provider
- ScheduleService: スケジュール CRUD + リアルタイムストリーム (Supabase stream)
- GroupService: グループ作成/招待コード参加/メンバー管理
- 認証ガード: go_router redirect で未認証時ログイン画面に自動遷移
- 認証状態プロバイダー (authStateProvider, currentUserProvider)
- Supabase CLI 初期化 (supabase init)
- DBスキーマ: 7テーブル + GiST インデックス + CHECK制約 + updated_at トリガー
- RLS ポリシー: 全7テーブルに Row Level Security 設定
- 開発用 seed データ (3ユーザー、1グループ、12スケジュール)
