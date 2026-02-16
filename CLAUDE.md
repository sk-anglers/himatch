# Himatch (ヒマッチ) - プロジェクト開発ルール

## プロジェクト概要

友達の空き時間を自動マッチング＆文脈付き提案する予定調整iOSアプリ。

## 技術スタック

- **フロントエンド**: Flutter (Dart) + Riverpod + go_router
- **バックエンド**: Supabase (PostgreSQL 16) + Edge Functions
- **リアルタイム**: Supabase Realtime
- **オフライン**: Drift (SQLite)
- **認証**: Supabase Auth (Apple / Google / LINE)
- **通知**: FCM
- **天気**: Open-Meteo (Phase 2)

## 開発ルール（6原則）

### 1. チケット駆動

- 全作業は GitHub Issue 作成後に着手
- ブランチ名: `feature/#<issue>-<description>` or `fix/#<issue>-<description>`

### 2. チケット更新 + PR

- 着手時・進捗時・完了時に Issue へコメント
- 完了時は PR 作成（`Closes #<issue>` で紐付け）

### 3. Claude Code レビュー

- PR 作成後、Claude Code（ローカル）が `gh pr diff` でレビュー
- approve / request-changes を `gh pr review` で投稿
- approve 後にマージ

### 4. CHANGELOG 更新

- 毎回 CHANGELOG.md を更新（Keep a Changelog 形式）
- [Unreleased] セクションに追記

### 5. ローカル作業 + push

- 作業ディレクトリ: `C:\Users\sanya\himatch`
- 完了時に必ず `git push`
- コミット: `<type>(#<issue>): <説明>`
  - type: feat / fix / chore / docs / refactor / test

### 6. 作業記録

- Issue に何をしたか・何を考えたか・問題を記録
- PR の description にも同様の情報を含める

## コーディング規約

- Dart: [Effective Dart](https://dart.dev/effective-dart) に準拠
- ファイル名: snake_case
- クラス名: PascalCase
- 変数・関数名: camelCase
- プライベートメンバー: _prefix
- import順序: dart: → package: → relative

## ディレクトリ構成（予定）

```
lib/
├── main.dart
├── app.dart
├── core/           # 共通ユーティリティ、定数、テーマ
├── features/       # 機能別モジュール
│   ├── auth/
│   ├── schedule/
│   ├── group/
│   └── suggestion/
├── models/         # データモデル
├── providers/      # Riverpod プロバイダー
├── services/       # Supabase、FCM等の外部サービス
└── widgets/        # 共通ウィジェット
```

## 重要ファイル

- `docs/TECH_DECISION.md` - 技術選定の根拠
- `docs/architecture.md` - システム設計（DBスキーマ、API、アルゴリズム）
- `docs/mvp-scope.md` - MVP機能スコープ
- `docs/ui-ux-design.md` - UI/UX設計
