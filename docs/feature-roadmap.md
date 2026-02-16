# Himatch 機能追加ロードマップ

> 競合17アプリの全機能を分析し、Himatchの差別化を維持しつつ網羅的に取り込む計画。
> 作成日: 2026-02-16

---

## 現状サマリー（実装済み）

| 機能 | 状態 |
|------|------|
| Apple/Google認証 + デモモード | ✅ |
| シフト/予定の手動入力（スタンプ式） | ✅ |
| グループ作成・招待コード | ✅ |
| グループカレンダー重ね合わせ | ✅ |
| 空き時間の自動検出 | ✅ |
| 文脈付き候補日提案（スコアリング） | ✅ |
| 投票（OK/微妙/NG）→ 確定フロー | ✅ |
| 天気予報連携（Open-Meteo 14日） | ✅ |
| 天気スコア統合 + 屋内/屋外提案 | ✅ |
| 日本の祝祭日表示 | ✅ |
| プッシュ通知（FCM基盤） | ✅ |
| カラーコード付きシフト管理 | ✅ |

---

## フェーズ構成

```
Phase 2A: 基盤強化（リリース後 1ヶ月）
Phase 2B: シフト強化 + ソーシャル（リリース後 2ヶ月）
Phase 3A: AI・外部連携（リリース後 3-4ヶ月）
Phase 3B: コミュニティ・エンタメ（リリース後 5-6ヶ月）
Phase 4:  プレミアム・エコシステム（リリース後 6ヶ月以降）
```

---

## Phase 2A: 基盤強化（リリース後 1ヶ月）

MVP直後に最も求められる機能群。離脱防止とリテンション向上が目的。

### 2A-1. カレンダー同期（Apple / Google）
**競合参考**: TimeTree, Fantastical, Google Calendar, スケコン

- Apple Calendar（EventKit）からの予定インポート
- Google Calendar API からの予定インポート
- 双方向同期（Himatch → 外部カレンダーへのエクスポート）
- 同期頻度: バックグラウンドで30分ごと + 手動更新
- インポートした予定は「予定あり」として自動反映
- 競合の全員が持つ基本機能。未対応だとユーザーが手動入力を面倒に感じて離脱する

**技術要件**:
- `device_calendar` パッケージ（iOS EventKit / Android Calendar Provider）
- Google Calendar API: OAuth 2.0 + REST API
- バックグラウンドフェッチ: `workmanager` パッケージ

**ファイル**:
- 新規: `lib/services/calendar_sync_service.dart`
- 新規: `lib/features/schedule/data/calendar_import_repository.dart`
- 新規: `lib/features/schedule/presentation/calendar_sync_settings_screen.dart`
- 修正: `lib/features/schedule/presentation/providers/schedule_providers.dart`
- 修正: `lib/features/profile/presentation/profile_tab.dart`（設定項目追加）
- 修正: `pubspec.yaml`（device_calendar, googleapis_auth 追加）

---

### 2A-2. 繰り返し予定
**競合参考**: Google Calendar, Fantastical, Calendars by Readdle

- iCal RRULE 形式で繰り返しルール保存（既にモデルに `recurrenceRule` フィールドあり）
- 対応パターン:
  - 毎日 / 毎週 / 隔週 / 毎月（日付指定 or 第N曜日） / 毎年
  - 終了条件: 永続 / N回 / 指定日まで
- 繰り返し予定の個別編集（この回のみ / 以降すべて / すべて）
- カレンダー表示時に動的展開

**ファイル**:
- 新規: `lib/core/utils/rrule_parser.dart`
- 修正: `lib/features/schedule/presentation/schedule_form_screen.dart`（繰り返し設定UI）
- 修正: `lib/features/schedule/presentation/providers/schedule_providers.dart`

---

### 2A-3. リマインダー・通知カスタマイズ
**競合参考**: Google Calendar, Fantastical, TimeTree

- 確定予定の前日・当日リマインド通知
- 通知タイミングのカスタマイズ（5分前 / 15分前 / 30分前 / 1時間前 / 1日前）
- 複数リマインダー設定（1予定に最大3つ）
- 未投票メンバーへの自動リマインド（提案後24h / 48h）
- グループ別通知設定（特定グループをミュート）

**ファイル**:
- 新規: `lib/services/reminder_service.dart`
- 修正: `lib/features/schedule/presentation/schedule_form_screen.dart`
- 修正: `lib/features/profile/presentation/profile_tab.dart`（通知設定画面）
- 修正: `lib/models/schedule.dart`（reminders フィールド追加）

---

### 2A-4. 週表示・日表示
**競合参考**: Google Calendar, Fantastical, Calendars by Readdle

- 月表示に加えて週表示・日表示を切り替え可能に
- 週表示: 横スクロールで時間軸、縦に曜日
- 日表示: 24時間タイムライン上にブロック表示
- 表示モード切り替え: カレンダー右上のトグルボタン

**ファイル**:
- 新規: `lib/features/schedule/presentation/widgets/week_view.dart`
- 新規: `lib/features/schedule/presentation/widgets/day_view.dart`
- 修正: `lib/features/schedule/presentation/calendar_tab.dart`（ビュー切り替え）

---

### 2A-5. iOS ホーム画面ウィジェット
**競合参考**: Fantastical, Yahoo!カレンダー, NurseCalendar, 全最新アプリ

- Small ウィジェット: 今日の天気 + 次の予定
- Medium ウィジェット: 今日〜3日間の予定 + 天気
- Large ウィジェット: 今週のカレンダー + シフト
- ロック画面ウィジェット: 次の予定 or 次のグループ集まり
- Live Activity: 確定予定の当日カウントダウン

**技術要件**:
- WidgetKit（Swift）+ App Groups でデータ共有
- Flutter → ネイティブ間のデータ橋渡し: `home_widget` パッケージ
- タイムラインプロバイダーで定期更新

**ファイル**:
- 新規: `ios/HimatchWidget/` ディレクトリ一式（Swift）
- 新規: `lib/services/widget_data_service.dart`
- 修正: `pubspec.yaml`（home_widget 追加）
- 修正: `ios/Runner.xcodeproj`（Widget Extension ターゲット追加）

---

### 2A-6. ヒートマップ空き時間可視化
**競合参考**: When2meet

- グループカレンダー画面に「ヒートマップモード」追加
- セルの色の濃さ = 空いているメンバーの人数
  - 全員空き: 濃い緑
  - 半数以上: 薄い緑
  - 半数未満: 黄色
  - 1人のみ: 薄い赤
  - 0人: グレー
- タップでメンバー名表示（「田中、鈴木、山本が空き」）
- 時間帯グリッド: 9:00-22:00 を1時間単位で表示
- **Himatchの独自差別化**: ヒートマップ + 文脈提案の組み合わせは世界初

**ファイル**:
- 新規: `lib/features/group/presentation/widgets/availability_heatmap.dart`
- 修正: `lib/features/group/presentation/group_calendar_screen.dart`（モード切替）

---

## Phase 2B: シフト強化 + ソーシャル（リリース後 2ヶ月）

シフトワーカー（バイト学生）のリテンションと、ソーシャル機能によるエンゲージメント向上。

### 2B-1. 給料計算
**競合参考**: シフトボード, シフト手帳 byGMO, 勤務ろぐ

- 勤務先ごとの時給設定（複数バイト対応）
- 月間・年間の給料自動計算
- 残業手当（法定 × 1.25）
- 深夜手当（22:00-5:00 × 1.25）
- 休日出勤手当（× 1.35）
- 交通費の定額加算
- 月間サマリー画面（総勤務時間 / 総給料 / 内訳グラフ）
- **103万・123万・130万の壁** アラート（年間収入が閾値に近づいたら警告）

**ファイル**:
- 新規: `lib/models/workplace.dart`（勤務先モデル: 時給, 深夜倍率, 締め日等）
- 新規: `lib/services/salary_calculator.dart`
- 新規: `lib/features/shift/presentation/salary_summary_screen.dart`
- 新規: `lib/features/shift/presentation/workplace_settings_screen.dart`
- 新規: `lib/features/shift/presentation/providers/salary_providers.dart`
- 修正: `lib/models/schedule.dart`（workplaceId 追加）
- 修正: ナビゲーション（シフト関連画面への導線）

---

### 2B-2. シフトパターン＆ローテーション
**競合参考**: NurseCalendar, シフカレ

- シフトパターンの保存と一括適用（既にモデルあり、UI強化）
- ローテーション自動入力（例: 早→遅→夜→休の4日周期）
- パターンの開始日指定 → 自動展開
- 1ヶ月分を20秒で入力（NurseCalendar同等のUX）
- シフトタイプ別アラーム（早番は5:30、遅番は12:00に通知）

**ファイル**:
- 新規: `lib/features/shift/presentation/shift_pattern_screen.dart`
- 新規: `lib/features/shift/presentation/shift_rotation_screen.dart`
- 修正: `lib/models/shift_pattern.dart`
- 修正: `lib/features/schedule/presentation/calendar_tab.dart`

---

### 2B-3. グループ内チャット
**競合参考**: TimeTree（イベント内チャット）, BAND

- グループごとのチャットルーム
- テキストメッセージ + 絵文字リアクション
- イベント紐付きチャット（「3/22の集まりについて」）
- 画像送信
- 既読表示
- チャット通知（グループ設定でオン/オフ）
- **Supabase Realtime** で実装（既にインフラ準備済み）

**ファイル**:
- 新規: `lib/models/chat_message.dart`
- 新規: `lib/features/chat/presentation/chat_screen.dart`
- 新規: `lib/features/chat/presentation/providers/chat_providers.dart`
- 新規: `lib/services/chat_service.dart`
- 修正: `lib/features/group/presentation/group_detail_screen.dart`（チャットボタン追加）
- DB: `chat_messages` テーブル追加

---

### 2B-4. アクティビティフィード + リアクション
**競合参考**: TimeTree（Activity機能）

- グループ内の変更履歴をフィード表示
  - 「田中さんが3/15にシフトを追加しました」
  - 「鈴木さんが候補日に投票しました」
  - 「予定が確定しました！🎉」
- 各フィードアイテムに絵文字リアクション（👍❤️😂🎉🙌）
- プルダウン更新
- 未読バッジ

**ファイル**:
- 新規: `lib/models/activity.dart`
- 新規: `lib/features/group/presentation/activity_feed_screen.dart`
- 新規: `lib/features/group/presentation/providers/activity_providers.dart`
- 修正: `lib/features/group/presentation/group_detail_screen.dart`
- DB: `activities` テーブル + `activity_reactions` テーブル

---

### 2B-5. テーマ・きせかえ
**競合参考**: Yahoo!カレンダー, NurseCalendar（150+テーマ）

- ダークモード対応
- カラーテーマ選択（パープル / ピンク / ブルー / グリーン / モノクロ）
- カレンダーのフォント切り替え（ゴシック / 丸ゴシック / 手書き風）
- 背景パターン（無地 / ドット / ストライプ）
- プロフィール画面からテーマ設定
- 将来的にはキャラクターコラボテーマ（課金対象）

**ファイル**:
- 新規: `lib/core/theme/app_themes.dart`（テーマバリエーション）
- 新規: `lib/features/profile/presentation/theme_settings_screen.dart`
- 修正: `lib/core/theme/app_theme.dart`（ダークモード追加）
- 修正: `lib/app.dart`（テーマ切り替えロジック）
- 修正: `lib/providers/`（テーマ設定 Provider）

---

### 2B-6. 共有ToDoリスト
**競合参考**: TimeTree, BAND, Google Calendar Tasks

- グループごとの共有ToDoリスト
- 用途: 持ち物リスト、買い出しリスト、やることリスト
- チェックボックス + 担当者割り当て
- 期限設定
- 確定した予定に紐付け可能（「BBQの準備リスト」）

**ファイル**:
- 新規: `lib/models/todo_item.dart`
- 新規: `lib/features/group/presentation/todo_list_screen.dart`
- 新規: `lib/features/group/presentation/providers/todo_providers.dart`
- 修正: `lib/features/group/presentation/group_detail_screen.dart`
- DB: `todo_items` テーブル

---

### 2B-7. 予定の公開範囲設定
**競合参考**: Google Calendar, TimeTree

- 予定ごとの公開範囲: 全員公開 / グループ限定 / 非公開
- グループごとのデフォルト公開範囲設定
- 非公開予定は「予定あり」とだけ表示（詳細非表示）
- 既にモデルに `visibility` フィールドあり → UI実装

**ファイル**:
- 修正: `lib/features/schedule/presentation/schedule_form_screen.dart`（公開範囲選択UI）
- 修正: `lib/features/group/presentation/group_calendar_screen.dart`（表示フィルタ）

---

## Phase 3A: AI・外部連携（リリース後 3-4ヶ月）

差別化を更に強化する高度な機能群。

### 3A-1. 自然言語入力
**競合参考**: Fantastical, Calendars by Readdle

- テキストから予定を自動解析
  - 「来週の金曜18時から飲み会」→ 日時 + タイトル自動設定
  - 「毎週月曜の早番」→ 繰り返し + シフトタイプ自動設定
  - 「3/22 終日 BBQ @代々木公園」→ 場所 + 終日フラグ
- 日本語特化の日時パーサー
  - 「来週」「再来週」「月末」「GW」等の相対表現
  - 「早番」「遅番」「夜勤」等のシフト用語
- 入力フィールドにリアルタイムプレビュー表示

**技術要件**:
- 日本語日時パーサー（自前実装 or パッケージ）
- フォールバック: パース失敗時は通常フォーム表示

**ファイル**:
- 新規: `lib/core/utils/natural_language_parser.dart`
- 新規: `lib/features/schedule/presentation/widgets/quick_input_field.dart`
- 修正: `lib/features/schedule/presentation/calendar_tab.dart`

---

### 3A-2. LINE連携
**競合参考**: LINEスケジュール, シフカレ, TimeTree

- LINE Login 認証（既にSub Auth対応予定だった）
- LINEグループへの招待リンク送信
- LINE経由のプッシュ通知（LINE Notify API）
- LINEトーク内での投票リマインド送信
- LINEプロフィール情報の取得

**技術要件**:
- LINE Login SDK for Flutter
- LINE Messaging API（Supabase Edge Function経由）
- LINE Notify API

**ファイル**:
- 新規: `lib/services/line_service.dart`
- 修正: `lib/features/auth/presentation/login_screen.dart`
- 修正: `lib/features/auth/providers/auth_providers.dart`
- 修正: `pubspec.yaml`
- 新規: `supabase/functions/line-notify/`（Edge Function）

---

### 3A-3. AI高度提案（行動学習）
**競合参考**: スケコン, Google Calendar Goals, Fantastical

- 過去の確定予定パターンを学習
  - 「このグループは月1で飲み会を確定している」→ 自動で飲み会候補を優先提案
  - 「金曜夜の提案が最も確定率が高い」→ 金曜夜の優先度UP
- メンバーのアクティビティ嗜好学習
  - 過去の投票パターンから「この人は屋外活動に高評価」を検出
- 最適時間帯の学習
  - 「このメンバーは18時以降の提案にOKが多い」
- 提案理由の表示（「このグループは金曜夜が人気です」）

**技術要件**:
- Phase 1: ルールベースの強化（確定履歴のカウント集計）
- Phase 2: Supabase Edge Function でスコアリングモデル
- Phase 3: 将来的にはオンデバイスML（Core ML）

**ファイル**:
- 新規: `lib/services/ai_suggestion_service.dart`
- 新規: `lib/features/suggestion/domain/learning_engine.dart`
- 修正: `lib/features/suggestion/domain/suggestion_engine.dart`
- DB: `suggestion_feedback` テーブル（確定/辞退のフィードバック蓄積）

---

### 3A-4. 場所提案・マップ連携
**競合参考**: Google Calendar, Fantastical（Travel Time）

- 予定に場所情報を付加（Apple Maps / Google Maps連携）
- メンバーの中間地点を自動算出
- 場所カテゴリ別のおすすめスポット検索
  - 居酒屋 / カフェ / カラオケ / 映画館 / 公園 等
- 移動時間の自動計算（電車 / 車 / 徒歩）
- 集合場所の地図リンク共有

**技術要件**:
- Apple MapKit / Google Maps SDK
- 外部API: ホットペッパー / 食べログ / Google Places API

**ファイル**:
- 新規: `lib/services/location_service.dart`
- 新規: `lib/features/suggestion/presentation/place_suggestion_screen.dart`
- 修正: `lib/models/suggestion.dart`（location フィールド追加）
- 修正: `lib/features/schedule/presentation/schedule_form_screen.dart`（場所入力）

---

### 3A-5. URL公開投票（非ユーザー向け）
**競合参考**: 調整さん, Doodle, When2meet

- アプリ未インストールの人でも参加できるWeb投票ページ
- グループ幹事がURL生成 → LINE/SNSで共有
- Web上で名前入力 + 日程投票（○△×）
- 投票結果はアプリ内にリアルタイム反映
- 匿名投票オプション
- 回答期限設定 + 自動ロック

**技術要件**:
- Flutter Web or Next.js で投票ページ
- Supabase の公開APIエンドポイント（RLS調整）

**ファイル**:
- 新規: `web/` ディレクトリ（Web投票ページ）
- 新規: `supabase/functions/public-vote/`（Edge Function）
- 修正: `lib/features/suggestion/presentation/providers/suggestion_providers.dart`

---

### 3A-6. 予定エクスポート
**競合参考**: 勤務ろぐ, シフトボード, シフカレ

- シフトをiCal形式でエクスポート
- 月間勤務表をPDF出力
- CSVエクスポート（勤務時間 + 給料データ）
- 共有シート経由で外部アプリへ送信

**ファイル**:
- 新規: `lib/services/export_service.dart`
- 新規: `lib/features/shift/presentation/export_screen.dart`
- 修正: `pubspec.yaml`（pdf, csv パッケージ追加）

---

## Phase 3B: コミュニティ・エンタメ（リリース後 5-6ヶ月）

ユーザーエンゲージメントとリテンションを最大化する機能群。

### 3B-1. グループアルバム
**競合参考**: TimeTree, BAND

- グループごとの共有写真アルバム
- 確定した予定に紐付けて写真を整理（「3/22 BBQ」フォルダ）
- 写真アップロード（Supabase Storage）
- コメント + リアクション
- アルバムのスライドショー表示

**ファイル**:
- 新規: `lib/models/photo.dart`
- 新規: `lib/features/group/presentation/album_screen.dart`
- 新規: `lib/services/storage_service.dart`
- DB: `photos` テーブル + Supabase Storage バケット

---

### 3B-2. グループ掲示板・投票
**競合参考**: BAND, Doodle

- グループ内掲示板（テキスト + 画像投稿）
- 汎用投票機能（日程以外にも「何食べる？」「どこ行く？」等）
- 選択肢は自由記述（2-10択）
- 複数回答可 / 匿名投票オプション
- 期限付き投票

**ファイル**:
- 新規: `lib/models/poll.dart`
- 新規: `lib/features/group/presentation/board_screen.dart`
- 新規: `lib/features/group/presentation/poll_screen.dart`
- DB: `posts` テーブル + `polls` テーブル + `poll_votes` テーブル

---

### 3B-3. 予定テンプレート
**競合参考**: Fantastical, Google Calendar

- よく使う予定のテンプレート保存
  - 「定例飲み会: 金曜 19:00-22:00, 渋谷, 参加メンバーA/B/C」
  - 「ランチ: 12:00-13:00, 職場近く」
- テンプレートからワンタップで予定作成
- グループ共有テンプレート

**ファイル**:
- 新規: `lib/models/event_template.dart`
- 新規: `lib/features/schedule/presentation/template_screen.dart`
- DB: `event_templates` テーブル

---

### 3B-4. 過去の予定履歴・統計
**競合参考**: Google Calendar Time Insights

- 遊んだ履歴の閲覧（グループごと）
- 月間・年間の統計ダッシュボード
  - 何回遊んだか
  - 最も一緒に遊んだ人
  - よく行くアクティビティ
  - 使った合計金額（割り勘連携時）
- 「思い出」機能（1年前の今日の予定を通知）

**ファイル**:
- 新規: `lib/features/history/presentation/history_screen.dart`
- 新規: `lib/features/history/presentation/stats_screen.dart`
- 新規: `lib/features/history/presentation/providers/history_providers.dart`

---

### 3B-5. SNS共有
**競合参考**: TimeTree, BAND, Instagram

- 確定した予定をInstagram Stories / LINE / X にシェア
- シェア用カード画像の自動生成
  - 日付 + 天気 + アクティビティ + メンバーアイコン
- 「みんなで遊んだ」記録のシェア
- 招待リンクのSNS向け OGP対応

**ファイル**:
- 新規: `lib/services/share_card_generator.dart`
- 新規: `lib/features/suggestion/presentation/share_card_screen.dart`
- 修正: `pubspec.yaml`（screenshot パッケージ追加）

---

### 3B-6. 割り勘・費用管理
**競合参考**: Phase 3 ロードマップ既出

- イベントごとの費用記録
- メンバーごとの支払い額入力
- 自動割り勘計算（均等割 / 傾斜割）
- 精算状況トラッキング（「田中→鈴木に500円」）
- 月間の支出サマリー

**ファイル**:
- 新規: `lib/models/expense.dart`
- 新規: `lib/features/expense/presentation/expense_screen.dart`
- 新規: `lib/features/expense/presentation/settlement_screen.dart`
- DB: `expenses` テーブル + `settlements` テーブル

---

## Phase 4: プレミアム・エコシステム（リリース後 6ヶ月以降）

収益化とプラットフォーム拡大。

### 4-1. Apple エコシステム統合
**競合参考**: Fantastical, Calendars by Readdle

- **Siri Shortcuts**: 「ヘイSiri、来週の予定を教えて」
- **Apple Watch アプリ**: 今日の予定 + 次のグループ集まり表示
- **Focus モード連携**: 仕事中は通知オフ、プライベート時はオン
- **Handoff**: iPhone ↔ iPad で作業継続
- **Live Activities**: 当日の予定をDynamic Island / ロック画面に表示

**ファイル**:
- 新規: `ios/HimatchWatch/` ディレクトリ（watchOS アプリ）
- 新規: `ios/Runner/SiriShortcuts/`
- 修正: `ios/Runner/Info.plist`（Siri, Focus 設定）

---

### 4-2. ヘルス＆ウェルビーイング
**競合参考**: Calendars by Readdle（Habit Tracker, Personal Reflections）

- 習慣トラッカー（ストリーク表示、リマインダー）
- ムード・エネルギー記録（予定と紐付け）
- 「どの活動が元気をくれるか」パターン分析
- 週間ウェルビーイングレポート
- Apple HealthKit 連携（睡眠・運動データ参照）

**ファイル**:
- 新規: `lib/features/wellbeing/` ディレクトリ一式
- 新規: `lib/models/habit.dart`, `lib/models/mood_entry.dart`
- 修正: `pubspec.yaml`（health パッケージ追加）

---

### 4-3. 予約ページ（Booking Page）
**競合参考**: Calendly, Doodle, Fantastical Openings

- 個人の空き時間公開ページ（URL共有）
- 他人がそのURLから予約を入れられる
- バッファ時間設定（予約間に30分の間隔）
- 1日の最大予約数制限
- 自動確認メール / LINE通知
- ユースケース: 個人レッスン講師、フリーランス、就活面談

**ファイル**:
- 新規: `lib/features/booking/` ディレクトリ一式
- 新規: `web/booking/`（公開予約ページ）
- DB: `booking_pages` テーブル + `bookings` テーブル

---

### 4-4. Android版
**競合参考**: 全アプリ（クロスプラットフォーム対応）

- Flutter ベースなのでコード共有率90%以上
- Android固有対応:
  - Material You テーマ
  - Android Widget（Glance API）
  - Google Wallet パス（確定予定をパスとして追加）
- Play Store 公開

---

### 4-5. プレミアムプラン（課金）
**収益化モデル**:

| 機能 | Free | Premium（月額480円） |
|------|------|---------------------|
| グループ数 | 3 | 無制限 |
| グループ人数 | 20人 | 50人 |
| カレンダー同期 | 1アカウント | 無制限 |
| テーマ | 5種類 | 全テーマ |
| 広告 | あり | なし |
| アルバム容量 | 500MB | 10GB |
| PDF/CSVエクスポート | × | ○ |
| 予約ページ | × | ○ |
| AI高度提案 | 基本 | フル |
| カスタムスタンプ | × | ○ |

---

## 全機能の競合マッピング

| # | 機能 | 競合アプリ | Phase | 優先度 |
|---|------|-----------|-------|--------|
| 1 | カレンダー同期（Apple/Google） | TimeTree, Fantastical, Google Cal | 2A | P0 |
| 2 | 繰り返し予定 | Google Cal, Fantastical | 2A | P0 |
| 3 | リマインダー・通知カスタマイズ | Google Cal, Fantastical, TimeTree | 2A | P1 |
| 4 | 週表示・日表示 | Google Cal, Fantastical, Readdle | 2A | P1 |
| 5 | iOS ウィジェット | Fantastical, Yahoo!, NurseCalendar | 2A | P1 |
| 6 | ヒートマップ空き時間可視化 | When2meet | 2A | P0 |
| 7 | 給料計算 | シフトボード, シフト手帳, 勤務ろぐ | 2B | P0 |
| 8 | シフトパターン＆ローテーション | NurseCalendar, シフカレ | 2B | P1 |
| 9 | グループ内チャット | TimeTree, BAND | 2B | P0 |
| 10 | アクティビティフィード + リアクション | TimeTree | 2B | P1 |
| 11 | テーマ・きせかえ | Yahoo!, NurseCalendar | 2B | P2 |
| 12 | 共有ToDoリスト | TimeTree, BAND, Google Tasks | 2B | P1 |
| 13 | 予定の公開範囲設定 | Google Cal, TimeTree | 2B | P1 |
| 14 | 自然言語入力 | Fantastical, Readdle | 3A | P1 |
| 15 | LINE連携 | LINEスケジュール, シフカレ | 3A | P0 |
| 16 | AI高度提案（行動学習） | スケコン, Google Cal Goals | 3A | P1 |
| 17 | 場所提案・マップ連携 | Google Cal, Fantastical | 3A | P1 |
| 18 | URL公開投票 | 調整さん, Doodle, When2meet | 3A | P0 |
| 19 | 予定エクスポート（PDF/CSV/iCal） | 勤務ろぐ, シフトボード | 3A | P2 |
| 20 | グループアルバム | TimeTree, BAND | 3B | P2 |
| 21 | グループ掲示板・投票 | BAND, Doodle | 3B | P2 |
| 22 | 予定テンプレート | Fantastical, Google Cal | 3B | P1 |
| 23 | 過去の予定履歴・統計 | Google Cal Time Insights | 3B | P1 |
| 24 | SNS共有 | TimeTree, BAND | 3B | P2 |
| 25 | 割り勘・費用管理 | 独自 | 3B | P2 |
| 26 | Apple エコシステム | Fantastical, Readdle | 4 | P1 |
| 27 | ヘルス＆ウェルビーイング | Readdle | 4 | P2 |
| 28 | 予約ページ | Calendly, Doodle, Fantastical | 4 | P2 |
| 29 | Android版 | 全アプリ | 4 | P0 |
| 30 | プレミアムプラン | 全アプリ | 4 | P0 |

---

## 差別化戦略サマリー

Himatchが競合に**ない**独自の組み合わせ:

| Himatch独自 | 類似機能を持つ競合 | Himatchの優位性 |
|------------|-------------------|----------------|
| 文脈付き候補日提案 | なし（世界初） | 空き時間 + 時間帯 + 天気から「何をするか」まで提案 |
| 天気 × スコアリング | Fantastical（天気表示のみ） | 天気を提案スコアに反映し活動内容を変える |
| ヒートマップ + 文脈提案 | When2meet（ヒートマップのみ） | 可視化 + 具体的提案の組み合わせ |
| シフト管理 + 遊び提案 | シフトボード（シフトのみ） | バイトのシフトから自動的に遊べる日を提案 |
| 給料計算 + 予定調整 | なし | 「稼いで、遊ぶ」を一つのアプリで完結 |

---

## 技術スタック追加予定

| Phase | パッケージ / サービス | 用途 |
|-------|---------------------|------|
| 2A | `device_calendar` | Apple/Google カレンダー同期 |
| 2A | `workmanager` | バックグラウンド同期 |
| 2A | `home_widget` | iOS ウィジェット |
| 2B | - | Supabase Realtime（チャット） |
| 3A | LINE Login SDK | LINE認証 |
| 3A | LINE Messaging API | LINE通知 |
| 3A | Google Places API | 場所検索 |
| 3A | `pdf`, `csv` | エクスポート |
| 3B | `screenshot` | SNS共有カード生成 |
| 4 | `health` | HealthKit連携 |
| 4 | WatchKit (Swift) | Apple Watch |
| 4 | RevenueCat | サブスクリプション管理 |

---

## 開発リソース見積もり

| Phase | 期間 | 主要機能数 | 開発者(想定) |
|-------|------|-----------|------------|
| 2A | 4週間 | 6機能 | 1-2名 |
| 2B | 4週間 | 7機能 | 1-2名 |
| 3A | 6週間 | 6機能 | 2名 |
| 3B | 4週間 | 6機能 | 1-2名 |
| 4 | 8週間+ | 5機能 | 2-3名 |

---

## 次のアクション

1. Phase 2A の実装着手（カレンダー同期 → ヒートマップの順）
2. Supabase DB スキーマ拡張設計（chat_messages, activities, workplace 等）
3. WidgetKit プロトタイプ作成
4. LINE Developer アカウント登録・API Key取得
5. App Store リリース準備と並行して Phase 2A 開発
