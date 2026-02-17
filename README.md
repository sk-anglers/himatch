# Himatch (ヒマッチ)

友達の空き時間を自動マッチング & 文脈付き提案する予定調整アプリ

## コンセプト

「いつ空いてる？」を聞くアプリではなく、**「この日、こう遊べるよ！」と教えてくれるアプリ**

メンバーのシフトや予定を共有し、全員の空き時間を自動検出。天気やパターン学習を加味した文脈付きアクティビティ提案で、「集まりたいけど調整が面倒」を解消します。

## 主要機能

### カレンダー & スケジュール

- **月/週/日 3モード表示** - table_calendar ベースの月表示、7日カラム週表示、24時間タイムライン日表示
- **シフトペイントモード** - シフト種別を選んで日付タップで連続入力（1日ずつフォームを開く必要なし）
- **自然言語入力** - 「来週火曜18時から飲み会@渋谷」のようなテキストから予定を自動パース
- **繰り返し予定** - iCalendar RRULE 準拠（DAILY/WEEKLY/MONTHLY/YEARLY）
- **テンプレート** - よく使う予定をアイコン・色付きテンプレートとして保存
- **カレンダー同期** - Apple/Google カレンダー連携設定
- **エクスポート** - iCal / CSV / PDF 形式で予定を外部出力

### 提案エンジン

- **空き時間自動マッチング** - 30分解像度でメンバーの空き時間を検出（8:00-22:00）
- **文脈付きアクティビティ提案** - 時間帯・長さに応じた提案（飲み会/ランチ/カフェ/日帰り旅行 等）
- **スコアリング** - 可用率 × 時間帯重み × 曜日重み で候補日をランク付け
- **天気予報連携** - Open-Meteo 14日予報を候補スコアに反映（±15%）、雨天時は屋内アクティビティを自動提案
- **AI学習エンジン** - 確定パターンから時間帯・曜日・アクティビティの好みを学習
- **投票・確定フロー** - 3択投票（OK/微妙/NG）→ オーナー確定 → セレブレーション表示
- **SNS共有カード** - 確定予定のシェアカード画像生成
- **公開投票URL** - URL経由で外部メンバーも投票可能

### グループ機能

- **グループ作成・招待コード参加** - 8桁コードで簡単参加
- **メンバーカレンダーオーバーレイ** - 全員の予定を重ね合わせ表示 + 「全員空き」日をハイライト
- **空き状況ヒートマップ** - メンバーの空き度合いを視覚化
- **グループチャット** - テキスト/画像メッセージ、リアクション、既読表示
- **投票** - 単一/複数選択、匿名投票、締切設定、リアルタイム結果
- **掲示板** - 投稿/コメント/リアクション、ピン留め
- **共有ToDoリスト** - 担当者アサイン、期限設定、完了チェック
- **アルバム** - 写真共有（グリッド表示、キャプション、リアクション）
- **アクティビティフィード** - 予定追加・投票・確定等のタイムライン
- **割り勘** - 経費トラッカー（均等/カスタム分割、精算計算）
- **通知バッジ** - 未読チャット・未投票・未完了ToDoのリアルタイムカウント

### シフト & 給料

- **勤務先管理** - 勤務先CRUD（名前/時給/締め日/各種割増率/交通費）
- **シフトパターン** - 早番/遅番/夜勤等のローテーション管理
- **給料計算** - 月間/年間の自動計算、残業・深夜・休日手当対応
- **税壁警告** - 103万/130万/150万の壁をアラート

### ウェルビーイング

- **気分/エネルギー/ストレストラッカー** - 日々のコンディション記録
- **習慣管理** - 日課の追跡

### プロフィール & 設定

- **テーマきせかえ** - 6色プリセット（紫/ピンク/青/緑/オレンジ/モノ）+ ダークモード
- **天気予報の地域設定** - GPS現在地 or 都市名検索
- **通知設定** - カテゴリ別ON/OFF + グループ別ミュート + リマインダー
- **予約ページ** - 空き時間公開 + 外部からの予約受付
- **履歴・統計** - 確定済み予定の履歴と統計情報
- **利用規約/プライバシーポリシー** - アプリ内閲覧
- **お問い合わせ** - カテゴリ選択付きフォーム

## デザインシステム

- **Material 3** ベース（`useMaterial3: true`, `ColorScheme.fromSeed`）
- カスタム TextTheme: 28/20/17/15/13/11pt の6段階タイプスケール
- `AppColorsExtension` によるライト/ダークモード完全対応
- `flutter_animate` によるアニメーション（shimmer、staggered fadeIn、slideUp/slideX）
- ページ遷移: fadeThrough (300ms) / slideUp (400ms)
- フラットカードデザイン（elevation 0 + outline border）

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| フロントエンド | Flutter 3.41 (Dart 3.11) |
| バックエンド | Supabase (PostgreSQL 16) |
| リアルタイム同期 | Supabase Realtime |
| オフラインキャッシュ | Drift (SQLite) |
| 状態管理 | Riverpod 3 |
| ルーティング | go_router 17 |
| UI コンポーネント | table_calendar, flutter_animate |
| データモデル | Freezed v3 + json_serializable |
| 天気API | Open-Meteo (CC-BY 4.0) |
| プッシュ通知 | FCM |
| 認証 | Supabase Auth + Apple / Google / LINE Login |

## プロジェクト構成

```
lib/
├── main.dart
├── app.dart
├── core/              # テーマ、定数、共通ウィジェット
│   ├── theme/         # AppTheme, AppColors, AppColorsExtension
│   ├── constants/     # AppConstants, AppSpacing, AppDateUtils
│   └── widgets/       # EmptyStateWidget, SkeletonLoader
├── features/          # 機能別モジュール
│   ├── auth/          # 認証 (デモモード / Supabase)
│   ├── booking/       # 予約ページ
│   ├── chat/          # グループチャット
│   ├── expense/       # 割り勘・経費
│   ├── group/         # グループ管理・投票・ToDo・アルバム・掲示板
│   ├── history/       # 履歴・統計
│   ├── profile/       # マイページ・設定
│   ├── schedule/      # カレンダー・予定管理
│   ├── shift/         # シフト・給料計算
│   ├── suggestion/    # 提案エンジン・天気
│   └── wellbeing/     # ウェルビーイング
├── models/            # データモデル (Freezed)
├── providers/         # グローバル Riverpod プロバイダー
├── routing/           # go_router ルーティング
└── services/          # WeatherService, SalaryCalculator 等
```

## セットアップ

### 前提条件

- Flutter 3.41+ / Dart 3.11+
- (任意) Supabase プロジェクト

### 手順

```bash
# リポジトリをクローン
git clone https://github.com/sk-anglers/himatch.git
cd himatch

# 依存パッケージをインストール
flutter pub get

# コード生成 (Freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 起動 (デモモードなら Supabase 不要)
flutter run
```

### Supabase 接続（任意）

```bash
cp .env.example .env
# .env に SUPABASE_URL と SUPABASE_ANON_KEY を設定
```

デモモードではログイン画面の「デモモードで始める」から Supabase 未接続でも全機能を操作できます。

## テスト

```bash
flutter test    # 53テスト (モデル/提案エンジン/投票/認証/グループ)
flutter analyze # 静的解析
```

## ドキュメント

- [MVP機能スコープ定義書](docs/mvp-scope.md)
- [UI/UX設計書](docs/ui-ux-design.md)
- [システム設計書](docs/architecture.md)
- [技術スタック選定レポート](docs/tech-stack.md)
- [技術選定 最終決定書](docs/TECH_DECISION.md)
- [変更履歴](CHANGELOG.md)

## ライセンス

Private - All Rights Reserved
