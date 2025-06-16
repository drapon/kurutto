# Apple Developer セットアップガイド

**重要**: TestFlightにアップロードする前に、Apple Developer側での準備が必要です。

## 必要な手順（順番通りに実行）

### 1. Apple Developer Programへの登録確認
- https://developer.apple.com にアクセス
- 有料メンバーシップ（年間$99）に登録済みか確認

### 2. Certificates, Identifiers & Profiles での設定

#### A. App ID（Bundle ID）の作成
1. https://developer.apple.com/account にログイン
2. 「Certificates, Identifiers & Profiles」を選択
3. 「Identifiers」→「+」ボタンをクリック
4. 「App IDs」を選択して「Continue」
5. 「App」を選択して「Continue」
6. 以下を入力：
   - **Description**: Kurutto
   - **Bundle ID**: Explicit を選択
   - **Bundle ID**: io.quon.kurutto
7. 「Capabilities」で必要な機能を確認（特別な機能は不要）
8. 「Continue」→「Register」

#### B. 開発証明書の作成（未作成の場合）
1. 「Certificates」→「+」ボタン
2. 「Apple Development」を選択
3. 指示に従ってCSRファイルをアップロード
4. 証明書をダウンロードしてインストール

#### C. 配布証明書の作成（未作成の場合）
1. 「Certificates」→「+」ボタン
2. 「Apple Distribution」を選択
3. 指示に従ってCSRファイルをアップロード
4. 証明書をダウンロードしてインストール

### 3. App Store Connect でアプリを作成

1. https://appstoreconnect.apple.com にログイン
2. 「マイApp」→「+」→「新規App」
3. 以下を入力：
   - **プラットフォーム**: iOS
   - **名前**: くるっと
   - **プライマリ言語**: 日本語
   - **バンドルID**: io.quon.kurutto（ドロップダウンから選択）
   - **SKU**: KURUTTO001（任意のユニークな文字列）
   - **ユーザーアクセス**: フルアクセス

4. 「作成」をクリック

### 4. TestFlight設定の準備

App Store Connectでアプリ作成後：
1. 左メニューから「TestFlight」を選択
2. 「テスト情報」に以下を入力：
   - **ベータ版App説明**: 
     ```
     3〜5歳向けの空間認識学習アプリです。
     動物たちと一緒に「前後・左右」を楽しく学べます。
     ```
   - **ベータ版Appレビューに関する情報**:
     - 連絡先メールアドレス
     - 連絡先電話番号
   - **ベータ版Appレビューのメモ**:
     ```
     子供向け教育アプリです。
     個人情報の収集はありません。
     インターネット接続は不要です。
     ```

### 5. Xcodeでの設定

App Store Connectでアプリを作成した後：

1. Xcodeでプロジェクトを開く
2. プロジェクト設定 → Signing & Capabilities
3. 「Automatically manage signing」にチェック
4. Team: あなたの開発者アカウントを選択
5. Bundle Identifier: io.quon.kurutto（自動で設定される）

## アップロードの流れ

すべての準備が完了したら：

1. **Xcode**: Product → Archive
2. **Organizer**: Distribute App → App Store Connect → Upload
3. **処理待ち**: 10-30分程度
4. **App Store Connect**: TestFlightタブでビルドが表示される
5. **内部テスター**: すぐに配信可能
6. **外部テスター**: ベータ版審査後（1-2日）

## チェックリスト

- [ ] Apple Developer Program 登録済み
- [ ] App ID (io.quon.kurutto) 作成済み
- [ ] 開発証明書インストール済み
- [ ] 配布証明書インストール済み
- [ ] App Store Connect でアプリ作成済み
- [ ] TestFlight テスト情報入力済み
- [ ] Xcode で Team 設定済み

## トラブルシューティング

### よくある問題

1. **「No account for team」エラー**
   - Xcode → Preferences → Accounts でアカウント追加

2. **Bundle ID が選択できない**
   - Apple Developer で App ID 作成を確認
   - Xcode を再起動

3. **証明書エラー**
   - Keychain Access で古い証明書を削除
   - 新しい証明書を再作成

4. **アップロードエラー**
   - Xcode と macOS を最新版に更新
   - Application Loader を使用（代替手段）

## 重要な注意事項

- Bundle ID は後から変更できないので、正確に入力
- SKU も変更不可なので、管理しやすい名前を選択
- 初回アップロードは時間がかかることがある
- TestFlight ビルドは90日間有効

これらの手順を完了すれば、TestFlightへのアップロードが可能になります。