# 技術スタック調査・選定レポート

## 1. フロントエンド: Swift/SwiftUI vs React Native vs Flutter

### 比較表

| 評価軸 | SwiftUI (ネイティブ) | React Native | Flutter |
|--------|---------------------|-------------|---------|
| **パフォーマンス** | ◎ 最高（Metal API直接アクセス、起動20-30%高速） | △ JSブリッジがボトルネック | ○ AOTコンパイルでほぼネイティブ |
| **UI品質 (iOS)** | ◎ 完全ネイティブ。Apple HIG準拠が自然 | ○ ネイティブコンポーネント使用 | ○ 独自レンダリング。iOS風に寄せられるが完全ではない |
| **開発速度** | ○ SwiftUI Previewあり | ◎ Hot Reload + JS既存資産 | ◎ Hot Reload + 豊富なウィジェット |
| **クロスプラットフォーム** | × iOS/macOSのみ | ◎ iOS + Android + Web | ◎ iOS + Android + Web + Desktop |
| **エコシステム** | ○ Apple公式フレームワーク充実 | ◎ npm巨大エコシステム | ○ 35,000+パッケージ（pub.dev） |
| **学習コスト** | △ Swiftの学習が必要 | ○ JS/TS知識があれば低い | △ Dart言語の学習が必要 |
| **LINE Login SDK** | ◎ 公式SDK（Swift 6対応、async/await対応） | ○ React Native用ラッパーあり | △ コミュニティプラグイン（公式なし） |
| **Apple Sign In** | ◎ ネイティブ統合 | ○ ライブラリ経由 | ○ ライブラリ経由 |
| **カレンダーUI** | ◎ EventKit直接利用 | ○ ライブラリ経由 | ○ ライブラリ経由 |
| **プッシュ通知** | ◎ APNs直接統合 | ○ FCM経由 | ○ FCM経由 |
| **将来のAndroid対応** | × 別途開発が必要 | ◎ 同一コードベース | ◎ 同一コードベース |
| **コミュニティ規模** | ○ Apple開発者 | ◎ 最大（世界の4.3%→9.4%はFlutter） | ◎ 急成長中 |

### 推奨: **Flutter**

**理由:**

1. **Phase 3でAndroid版が計画されている** — SwiftUIを選ぶとAndroid版の際に全面書き直しが必要。Flutterなら同一コードベースで展開可能
2. **開発速度** — Hot Reloadにより、MVP 6-8週間の目標に対して最も効率的。SwiftUIのPreviewは機能的だがHot Reloadほど高速ではない
3. **パフォーマンス** — AOTコンパイルによりほぼネイティブ性能。本アプリはカレンダーUIとリスト表示が中心で、ゲームのような高負荷処理は不要
4. **UI自由度** — 文脈付き提案のカードUI、投票UIなど独自デザインが多い。Flutterの独自レンダリングエンジンはカスタムUIに強い
5. **LINE Login** — 公式SDKはないが、コミュニティプラグイン（`flutter_line_sdk`）があり、基本機能は問題なく利用可能。最悪の場合はPlatform Channelでネイティブ呼び出しが可能

**React Nativeを選ばない理由:**
- JSブリッジによるパフォーマンスボトルネック。リアルタイムのカレンダー更新で体感差が出る可能性
- 2026年時点でFlutterの方がモバイルアプリ開発のトレンドとして勢いがある

**SwiftUIを選ばない理由:**
- Android対応時に全面書き直しが必要（Phase 3のコスト増大）
- ただし、iOS専用で割り切るならSwiftUIが最良の選択肢。判断はビジネス戦略次第

### 代替案: SwiftUI（iOS専用戦略）

もしPhase 3のAndroid版を見送る/外注する判断であれば、SwiftUIを推奨:
- LINE Login公式SDK（Swift 6 + async/await対応）が最も安定
- Apple Sign In、EventKit、APNsの統合が最もスムーズ
- iOSユーザー体験が最も高品質

---

## 2. バックエンド: Firebase vs Supabase vs カスタムサーバー

### 比較表

| 評価軸 | Firebase | Supabase | カスタム (Node.js) |
|--------|----------|----------|--------------------|
| **リアルタイム同期** | ◎ 最強。オフライン対応、自動競合解決 | ○ PostgreSQL WALベース。Web向きだがモバイルも改善中 | △ 自前実装（WebSocket/SSE） |
| **認証** | ◎ Apple/Google/匿名ログイン標準搭載 | ◎ Apple/Google/OAuth標準搭載 | △ Passport.js等で自前構築 |
| **LINE Login** | △ カスタム認証トークンで統合可能 | △ カスタムOAuthプロバイダーで統合可能 | ○ 自由に実装可能 |
| **データモデル** | △ NoSQL（Firestore）。JOINなし、非正規化が必要 | ◎ PostgreSQL。JOIN、外部キー、複雑クエリ対応 | ◎ 自由にDBを選択可能 |
| **スケーラビリティ** | ◎ Google Cloudで自動スケール | ○ マネージドPostgreSQL | △ 自前でスケール設計必要 |
| **無料枠** | ○ Spark: 50K読取/日, 20K書込/日, 1GB | ○ 500MB DB, 50K MAU, APIリクエスト無制限 | × インフラ費用が初日から発生 |
| **開発速度** | ◎ SDK充実、コード最小限 | ◎ SDK充実、ダッシュボード優秀 | × API設計・実装に時間 |
| **Flutter対応** | ◎ 公式FlutterFire | ○ 公式Dart Client | △ HTTP Client自前実装 |
| **コスト予測性** | △ 従量課金で予測困難 | ◎ 月額固定（Pro $25/月） | ○ サーバー費用は固定 |
| **ベンダーロックイン** | × Google依存 | ○ オープンソース、セルフホスト可 | ◎ 完全自由 |
| **オフラインサポート** | ◎ Firestoreにオフラインキャッシュ内蔵 | △ 自前で実装必要 | × 自前で実装必要 |

### 推奨: **Firebase (Firestore + Auth + FCM)**

**理由:**

1. **リアルタイム同期が最強** — 本アプリの核心は「メンバーの予定がリアルタイムに更新される」こと。Firestoreのリアルタイムリスナーは最も成熟しており、オフライン時のキャッシュも自動
2. **オフラインサポート** — 電車の中など通信不安定な環境でもアプリが動作。予定入力 → オンライン時に自動同期
3. **Flutter公式対応** — FlutterFireは最も充実したFirebase Flutter統合。ドキュメント・サンプル豊富
4. **FCMでプッシュ通知** — Firebase Cloud Messagingが標準搭載。APNs経由の配信もFCMが自動処理
5. **MVP開発速度** — バックエンドコード最小限で6-8週間の目標に最適
6. **無料枠でMVP検証可能** — DAU 500人規模なら無料枠で十分運用可能

**データモデルの懸念と対策:**
- Firestoreは NoSQL のため、「グループ全員の空き時間をJOINで集計」のような操作は苦手
- **対策**: Cloud Functions でサーバーサイド集計。または非正規化（メンバーの空き時間をグループドキュメントに埋め込む）
- 文脈付き提案ロジックはCloud Functions内のルールベース処理で実装

**LINE Loginの統合方法:**
- Firebase AuthのカスタムトークンでLINE Loginを統合
- フロー: Flutter → LINE SDK → アクセストークン取得 → Cloud Functions → LINE API検証 → Firebase カスタムトークン発行 → Flutter → Firebase Authにログイン

### Supabaseを選ばない理由:
- モバイル向けリアルタイム同期がFirebaseほど成熟していない
- オフラインサポートが標準で組み込まれていない（モバイルアプリでは重要）
- 無料枠のプロジェクト自動停止（1週間APIリクエストなしで停止）が本番運用に不向き

### カスタムサーバーを選ばない理由:
- MVP 6-8週間の目標に対してインフラ構築の時間が取れない
- 1人〜少人数チームでバックエンド運用まで手が回らない

---

## 3. データベース

### 推奨: **Cloud Firestore（Firebaseに内包）**

バックエンドにFirebaseを選択したため、データベースは自動的にCloud Firestoreとなる。

### データモデル設計方針

Firestoreはドキュメント指向NoSQL。以下の構造を推奨:

```
users/{userId}
  - displayName: string
  - iconUrl: string
  - authProvider: "apple" | "line" | "google"
  - createdAt: timestamp

users/{userId}/schedules/{scheduleId}
  - date: timestamp
  - startTime: string ("09:00")
  - endTime: string ("17:00")
  - status: "work" | "busy" | "free"
  - category: "work" | "school" | "private"

groups/{groupId}
  - name: string
  - createdBy: userId (ref)
  - inviteCode: string
  - memberIds: [userId, ...]
  - maxMembers: 20
  - createdAt: timestamp

groups/{groupId}/suggestions/{suggestionId}
  - date: timestamp
  - startTime: string
  - endTime: string
  - durationHours: number
  - contextLabel: "all_day" | "half_day" | "evening" | "lunch" | "morning"
  - suggestionText: string
  - votes: { userId: "ok" | "maybe" | "ng" }
  - status: "proposed" | "confirmed" | "expired"
  - confirmedAt: timestamp | null
```

### 非正規化戦略

リアルタイム表示のため、以下のデータを非正規化して保持:
- `groups/{groupId}/memberSchedules/{userId}` — グループ内表示用にメンバーの予定をコピー
- Cloud FunctionsのFirestoreトリガーで、`users/{userId}/schedules` の変更を検知し、所属グループに自動反映

---

## 4. 天気予報API（Phase 2向け調査）

### 比較表

| 評価軸 | OpenWeatherMap | WeatherAPI.com | Apple WeatherKit |
|--------|---------------|----------------|-----------------|
| **無料枠** | 1,000コール/日 (One Call API 3.0) | 1,000,000コール/月 (無料) | 500,000コール/月 (Apple Developer Program内) |
| **日本の精度** | ○ グローバルモデル | ○ グローバルモデル | ◎ 気象庁データ直接利用 |
| **予報期間** | 8日先まで | 14日先まで | 10日先まで |
| **レスポンス速度** | ○ | ◎ グローバルキャッシュ | ○ |
| **データ粒度** | ○ 3時間ごと | ○ 1時間ごと | ◎ 1時間ごと + 分単位 |
| **Flutter対応** | ◎ REST API（HTTP呼び出し） | ◎ REST API（HTTP呼び出し） | △ REST APIあるがApple認証が必要 |
| **月額コスト (有料)** | $0〜（従量制） | $0〜$35/月 | Apple Developer $99/年に含む |
| **導入の容易さ** | ◎ APIキーのみ | ◎ APIキーのみ | △ JWT認証が必要 |

### 推奨: **WeatherAPI.com**（Phase 2実装時）

**理由:**

1. **無料枠が最大** — 月100万コールは本アプリの規模で十分（MAU 5,000 × 日20回アクセス = 月300万 → 天気APIは候補日表示時のみなので実質月数万コール）
2. **14日先予報** — 他社の8-10日より長い。2週間先の候補日にも天気を表示できる
3. **REST API** — Flutterからの呼び出しが最もシンプル。特別なSDKやJWT認証不要
4. **日本対応** — グローバルモデルだが、主要都市の精度は実用的

**Apple WeatherKitを選ばない理由:**
- JWT認証が必要で実装がやや複雑
- Flutterからの呼び出しにApple認証トークンの管理が必要
- ただし日本の気象庁データを直接利用している点は魅力的。Flutter → Cloud Functions → WeatherKit REST APIという構成なら採用余地あり

**Phase 2実装時の推奨構成:**
- Cloud Functionsで天気APIを呼び出し（APIキーをサーバーサイドに保持）
- 結果をFirestoreにキャッシュ（1日1回更新）
- クライアントはFirestoreから天気データを取得（リアルタイムリスナー）

---

## 5. プッシュ通知

### 推奨: **Firebase Cloud Messaging (FCM)**

| 機能 | FCM |
|------|-----|
| iOS対応 | ◎ APNs経由で自動配信 |
| Android対応 | ◎ ネイティブ対応 |
| Flutter対応 | ◎ `firebase_messaging` パッケージ |
| トピック配信 | ◎ グループ単位でトピック購読 |
| コスト | 無料（無制限） |
| スケジュール配信 | ○ Cloud Functionsと組み合わせ |

Firebaseを選択した場合、FCMが自然な選択。追加のサービス不要。

**通知設計:**
- グループ単位でFCMトピックを作成（`group_{groupId}`）
- 新規提案・投票リマインド・予定確定をトピック配信
- 個別通知（投票リマインド等）はユーザーFCMトークンに直接配信
- Cloud FunctionsのFirestoreトリガーで自動配信

---

## 6. 認証

### 推奨構成

| 認証方法 | 実装方針 | 優先度 |
|---------|---------|--------|
| **Apple Sign In** | Firebase Auth標準搭載。App Store要件で必須 | P0 (MVP) |
| **LINE Login** | LINE SDK → Cloud Functions → Firebase カスタムトークン | P0 (MVP) |
| **Google Sign In** | Firebase Auth標準搭載 | P1 (Phase 2で追加検討) |

**Apple Sign Inが必須な理由:**
- App Storeガイドライン: サードパーティログインを提供する場合、Apple Sign Inも提供必須

**LINE Loginの統合フロー:**
```
1. Flutter: LINE SDK for Flutter でLINEログイン実行
2. Flutter: LINEアクセストークンを取得
3. Flutter → Cloud Functions: アクセストークンを送信
4. Cloud Functions → LINE API: トークン検証 + プロフィール取得
5. Cloud Functions → Firebase Auth: カスタムトークン生成
6. Cloud Functions → Flutter: カスタムトークン返却
7. Flutter → Firebase Auth: カスタムトークンでサインイン
```

---

## 7. 推奨技術スタック（まとめ）

| レイヤー | 技術 | 理由 |
|---------|------|------|
| **フロントエンド** | Flutter (Dart) | クロスプラットフォーム対応 + Hot Reload + カスタムUI |
| **バックエンド** | Firebase (Cloud Functions) | リアルタイム同期 + オフライン対応 + MVP開発速度 |
| **データベース** | Cloud Firestore | Firebase統合 + リアルタイムリスナー |
| **認証** | Firebase Auth + LINE SDK | Apple/Google標準 + LINEカスタム統合 |
| **プッシュ通知** | Firebase Cloud Messaging (FCM) | 無料 + APNs自動連携 + トピック配信 |
| **天気API (Phase 2)** | WeatherAPI.com | 無料枠最大 + 14日予報 + REST API |
| **ホスティング** | Firebase Hosting | 招待リンクのランディングページ・Dynamic Links |
| **分析** | Firebase Analytics + Crashlytics | KPI計測 + クラッシュ監視 |
| **CI/CD** | GitHub Actions + Fastlane | 自動ビルド + App Store配信 |

---

## 8. 初期コスト見積もり

### MVP期間（開発中〜リリース直後）

| 項目 | 月額コスト | 備考 |
|------|-----------|------|
| Firebase (Spark プラン) | **$0** | 無料枠内で十分 |
| Apple Developer Program | **$99/年** ($8.25/月) | App Store公開に必須 |
| LINE Developers | **$0** | 無料（LINE Login API） |
| GitHub (Free) | **$0** | プライベートリポジトリ無料 |
| ドメイン（招待リンク用） | **~$12/年** ($1/月) | オプション |
| **合計** | **約 $9/月** | |

### リリース後（MAU 5,000規模）

| 項目 | 月額コスト | 備考 |
|------|-----------|------|
| Firebase (Blaze プラン) | **$25-50/月** | 従量課金。読取/書込量次第 |
| Apple Developer Program | **$8.25/月** | |
| WeatherAPI.com (Phase 2) | **$0** | 無料枠内 |
| **合計** | **約 $35-60/月** | |

### スケール後（MAU 50,000規模）

| 項目 | 月額コスト | 備考 |
|------|-----------|------|
| Firebase (Blaze プラン) | **$100-300/月** | Firestore読取が主要コスト |
| Apple Developer Program | **$8.25/月** | |
| WeatherAPI.com (有料) | **$0-35/月** | 利用量次第 |
| **合計** | **約 $110-345/月** | |

---

## 9. 技術リスクと軽減策

| リスク | 影響度 | 軽減策 |
|--------|--------|--------|
| Firestoreの非正規化によるデータ不整合 | 中 | Cloud Functionsのトリガーで整合性を保証。トランザクション活用 |
| FlutterのLINE Login SDKが不安定 | 中 | Platform Channelで各OSネイティブSDKを直接呼び出すフォールバック |
| Firebase従量課金の急増 | 中 | Firestore読取を最小化（キャッシュ活用、リアルタイムリスナーの適切な管理） |
| Flutter iOSのネイティブ感不足 | 低 | Cupertino ウィジェット活用。iOS HIG準拠のデザイン |
| Cloud Functions Cold Start | 低 | 最小インスタンス設定（有料）or 定期ウォームアップ |

---

## 10. 開発環境セットアップ

### 必要なツール

```
- Flutter SDK (stable channel)
- Dart SDK (Flutter同梱)
- Android Studio or VS Code (Flutter拡張)
- Xcode (iOS ビルド用)
- Firebase CLI (`firebase-tools`)
- FlutterFire CLI (`flutterfire_cli`)
- CocoaPods (iOS依存管理)
```

### 主要パッケージ (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_messaging: ^15.x
  firebase_analytics: ^11.x

  # 認証
  sign_in_with_apple: ^6.x
  flutter_line_sdk: ^3.x

  # UI
  table_calendar: ^3.x        # カレンダーUI
  flutter_riverpod: ^2.x      # 状態管理
  go_router: ^14.x            # ルーティング

  # ユーティリティ
  intl: ^0.19.x               # 日付フォーマット
  share_plus: ^9.x            # 招待リンク共有
  qr_flutter: ^4.x            # QRコード生成
  mobile_scanner: ^5.x        # QRコードスキャン
```
