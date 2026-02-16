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
- カレンダーUI: table_calendar 統合 (月/2週/週 表示切替、日本語ロケール)
- スケジュール一覧: 日付タップで当日の予定一覧表示 (種別バッジ + 時刻)
- スケジュール追加/編集画面: 種別選択 (シフト/予定/空き/不可)、日時ピッカー、終日切替、メモ
- スケジュール削除: 確認ダイアログ付き
- ローカル状態管理: LocalSchedulesNotifier (オフラインファースト開発用)
- 日本語ローカライゼーション (flutter_localizations)
- グループ一覧画面 (GroupsTab): 参加グループ一覧 + 空状態表示
- グループ作成ダイアログ: グループ名 + 説明入力
- グループ詳細画面 (GroupDetailScreen): メンバー一覧 + 招待コード表示/コピー/共有
- 招待コード参加ダイアログ: 8桁コード入力 (大文字自動変換 + バリデーション)
- グループ退出機能 (確認ダイアログ付き)
- ローカルグループ状態管理 (LocalGroupsNotifier / LocalGroupMembersNotifier)
- グループ機能テスト (13テスト)
- 候補日提案エンジン (SuggestionEngine): 空き時間重複検出 + 文脈付きアクティビティ提案
  - 30分解像度でメンバー空き時間スキャン (8:00-22:00)
  - TimeCategory 自動分類 (朝/昼/午後/夜/終日)
  - ActivityType 推定 (ランチ/飲み会/カフェ/日帰り旅行 etc.)
  - スコアリング: 可用率 × 時間帯重み × 曜日重み
- 提案タブUI (SuggestionsTab): 候補日カード一覧 + スコア表示 + 参加可能率バー
- 提案カード操作: 承認 (Accept) / 見送り (Decline) ステータス変更
- ローカル提案状態管理 (LocalSuggestionsNotifier)
- 提案エンジンテスト (12テスト)
- マイページUI (ProfileTab): プロフィール表示 + 設定 + アカウント管理
  - プロフィールヘッダー (アバター/表示名編集/グループ数・スケジュール数)
  - 設定: 通知ON/OFF、デフォルト公開範囲 (全員/友達/自分)
  - アカウント: ログアウト (確認ダイアログ付き)
  - アプリ情報: バージョン/利用規約/プライバシーポリシー
- 全4タブのプレースホルダー完全差替 (HomeScreen にプレースホルダーなし)
- デモモード認証: ログイン画面「デモモードで始める」でSupabase未接続でも全機能操作可能
- AuthNotifier: 統合認証状態管理 (none/demo/supabase モード)
- go_router: AuthNotifier ベースのリダイレクトに移行
- main.dart: Supabase 初期化の安全化 (未設定時・接続失敗時もクラッシュしない)
- ProfileTab: デモモードバナー表示 + ログアウトで AuthNotifier.signOut
- .env.example: Supabase 環境変数テンプレート
- 認証テスト (4テスト)
- 投票・確定フロー: 候補日に対してメンバーが「参加OK」「微妙」「NG」の3択で投票
  - Vote モデル (Freezed): userId + suggestionId + voteType (ok/maybe/ng) + displayName
  - LocalVotesNotifier: castVote (投票/再投票)、getUserVote、getVoteSummary、clearVotes
  - SuggestionStatus.confirmed: グループオーナーが「この日に決定」で確定
  - confirmSuggestion: 確定時に同グループの他候補を自動 decline
  - 投票UI: 3色ボタン (緑=OK, 黄=微妙, 赤=NG) + 選択状態のハイライト
  - 投票集計表示: OK/微妙/NG カウント + スタックドバー + 投票者名タグ
  - 確定ボタン: グループオーナーかつ投票あり時のみ表示 + 確認ダイアログ
  - 確定済み候補: 緑ボーダー + 「予定確定！」セレブレーション表示
  - セクション分類: 確定済み / 投票受付中 / 承認済み で候補を整理表示
- 投票テスト (14テスト): Vote モデル、VotesNotifier CRUD、VoteSummary
