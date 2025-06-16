# TestFlight 配信チェックリスト

## 事前準備（Apple Developer）

### 1. Apple Developer Program ✓
- [ ] 有料メンバーシップ（$99/年）登録済み
- [ ] 支払い完了・有効化済み

### 2. Certificates, Identifiers & Profiles ✓
- [ ] **App ID 作成**
  - Bundle ID: `io.quon.kurutto`
  - Description: Kurutto
- [ ] **開発証明書** (Apple Development)
- [ ] **配布証明書** (Apple Distribution)
- [ ] 証明書をMacにインストール済み

### 3. App Store Connect ✓
- [ ] **新規App作成**
  - 名前: くるっと
  - バンドルID: io.quon.kurutto
  - SKU: 任意（例: KURUTTO001）
- [ ] **TestFlight情報入力**
  - ベータ版App説明
  - 連絡先情報
  - レビューメモ

## Xcodeでの作業

### 4. プロジェクト設定 ✓
- [ ] **Signing & Capabilities**
  - Team: 選択済み
  - Automatically manage signing: ON
  - Bundle Identifier: io.quon.kurutto
- [ ] **ビルド設定確認**
  - iOS Deployment Target: 15.0
  - 有効なアーキテクチャ: arm64

### 5. ビルド前の最終確認 ✓
- [ ] **プロジェクトがビルドできる**
  - スキーム: Kurutto
  - デバイス: Any iOS Device (arm64)
- [ ] **アイコン設定済み**（✅ 完了）
- [ ] **Info.plist確認**（✅ 完了）

### 6. アーカイブ作成 ✓
- [ ] Product → Clean Build Folder
- [ ] Product → Archive
- [ ] アーカイブ成功

### 7. アップロード ✓
- [ ] Organizer → Distribute App
- [ ] App Store Connect を選択
- [ ] Upload を選択
- [ ] オプション確認（通常はデフォルト）
- [ ] アップロード完了

## App Store Connect での確認

### 8. ビルド処理 ✓
- [ ] 処理中ステータス確認（10-30分）
- [ ] 処理完了通知（メール）

### 9. TestFlight設定 ✓
- [ ] ビルドが表示される
- [ ] ビルドの「管理」をクリック
- [ ] 輸出コンプライアンス情報を入力
  - 暗号化を使用していない → いいえ

### 10. テスター招待 ✓
- [ ] **内部テスト**（すぐ配信可能）
  - App Store Connect ユーザーを追加
  - 最大100名
- [ ] **外部テスト**（審査必要）
  - グループ作成
  - テスターのメールアドレス追加
  - ベータ版審査提出（1-2日）

## トラブルシューティング

### よくあるエラーと対処法

1. **「Team不明」エラー**
   ```
   Xcode → Settings → Accounts → Apple IDを追加
   ```

2. **証明書エラー**
   ```
   Keychain Access で重複/期限切れ証明書を削除
   ```

3. **アップロードエラー**
   ```
   - Xcodeを最新版に更新
   - ネットワーク接続確認
   - Transporter アプリを使用（代替手段）
   ```

4. **ビルドが表示されない**
   ```
   - 処理完了まで待つ（最大1時間）
   - App Store Connect をリロード
   - メールで拒否通知を確認
   ```

## 現在の状態

### ✅ 完了済み
- Xcodeプロジェクトのビルドエラー修正
- アプリアイコン生成・設定
- 音声ファイル対応
- Info.plist設定

### ⏳ 開発者のアクション待ち
- Apple Developer Program での App ID 作成
- App Store Connect でのアプリ作成
- Xcode での Team 設定
- アーカイブとアップロード

---

**注**: このチェックリストを順番に進めることで、スムーズにTestFlight配信ができます。