|              言語選択              |                 언어선택                 |
| :--------------------------------: | :--------------------------------------: |
| 🇯🇵 [日本語 (README.md)](README.md) | 🇰🇷 [한국어 (README_kr.md)](README_kr.md) |

# smart_kintai

Flutter + Supabase ベースの勤怠管理（出退勤）アプリ

## プロジェクト目的

- このプロジェクトは、バイブコーディングの体験を目的として作成されました。
- AI を活用することで、コーディング自体の時間は短縮されました。
- 一方で、AI に適切なコンテキストを提供する時間や、期待通りのコードが生成されなかった場合の追加作業が新たに発生しました。
- プロジェクトの規模（コード量・考慮ドメイン）が大きくなるほど、  
  上記プロセスにより「バイブコーディング」の方が従来よりも時間を要する可能性があると感じています。

## 紹介

**smart_kintai**は Flutter と Supabase を活用し、出勤・退勤記録を管理するシンプルな勤怠管理アプリです。  
ログイン/新規登録、出勤/退勤記録、ID 保存、セッション切れ対応などの基本機能を提供します。

## 主な機能

- **新規登録/ログイン**: Supabase 認証を利用したメールアドレスによる新規登録・ログイン
- **ID 保存**: ログイン時にメールアドレス（ID）を保存する機能（SharedPreferences 使用）
- **出勤/退勤記録**: ボタンを押すだけで出勤・退勤記録を Supabase DB に保存
- **本日の出勤状態確認**: アプリ起動時に本日の最新の出勤/退勤状態を自動取得
- **セッション切れ/ログアウト**: セッション切れ時の案内と再ログイン誘導、ログアウト機能
- **Flutter Cupertino スタイル UI**: iOS 風のシンプルな UI（一部 shadcn 使用）

## 使用技術

- Flutter 3.32.6
- Supabase（認証、DB）
- shadcn_flutter（UI コンポーネント）
- shared_preferences（ローカル保存）
- flutter_dotenv（環境変数管理）

## 実行方法

1. `.env`ファイルに Supabase プロジェクトの URL と anon key を入力します。
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
2. パッケージをインストール
   ```
   flutter pub get
   ```
3. アプリを実行
   ```
   flutter run
   ```

## 主な画面

- **ログイン/新規登録**

  - メールアドレス、パスワード入力
  - ID 保存スイッチ
  - ログイン/新規登録ボタン

- **メイン（勤怠管理）**
  - 出勤/退勤ボタン（状態に応じて切り替え）
  - 画面上部にログアウトボタン

## テーブル構成例（Supabase）

- `kintai_start_end`
  - `id`: PK
  - `uid`: ユーザー ID（auth の user.id）
  - `is_start`: bool（true: 出勤, false: 退勤）
  - `created_at`: timestamp

## 参考

- Flutter、Supabase 公式ドキュメント
- shadcn_flutter: https://pub.dev/packages/shadcn_flutter

## ライセンス

MIT
