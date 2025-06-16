# くるっと (Kurutto)

3〜5歳向けの空間認識能力を育てる iOS 教育ゲームアプリ

## 📱 概要

「くるっと」は、未就学児（3〜5歳）が楽しく遊びながら「前後・左右・上下」の空間認識能力を身につけることができる教育ゲームアプリです。3D回転ボードと可愛い動物キャラクターを使って、子供たちが直感的に空間の概念を理解できるように設計されています。

## 🎯 主な特徴

- **年齢別難易度設定**: 3歳、4歳、5歳それぞれに最適化された問題
- **3D回転ボード**: SceneKitを使用した滑らかな3D表現
- **音声ガイド**: すべての問題を音声で読み上げ
- **ポジティブフィードバック**: 間違えても楽しく続けられる設計
- **保護者向け機能**: 学習進捗の確認が可能

## 🛠 技術スタック

- **Platform**: iOS 15.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **3D Graphics**: SceneKit
- **Animation**: Lottie
- **Audio**: AVFoundation
- **Data Persistence**: CoreData

## 📋 必要な開発環境

- macOS 13.0 以上
- Xcode 15.0 以上
- iOS 15.0 以上の実機またはシミュレーター

## 🚀 セットアップ

1. リポジトリをクローン
```bash
git clone https://github.com/yourusername/kurutto.git
cd kurutto
```

2. Xcodeでプロジェクトを開く
```bash
open Kurutto.xcodeproj
```

3. 依存関係をインストール（Swift Package Manager使用）
   - Xcodeが自動的に依存関係を解決します

4. ビルドして実行
   - ターゲットデバイスを選択
   - Cmd + R でビルド&実行

## 📁 プロジェクト構造

```
Kurutto/
├── App/
│   ├── KuruttoApp.swift
│   └── Info.plist
├── Views/
│   ├── GameView.swift
│   ├── MenuView.swift
│   ├── SettingsView.swift
│   └── Components/
├── ViewModels/
│   ├── GameViewModel.swift
│   └── UserProgressViewModel.swift
├── Models/
│   ├── Question.swift
│   ├── Animal.swift
│   └── GameState.swift
├── Services/
│   ├── AudioManager.swift
│   ├── SceneManager.swift
│   └── DataManager.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Sounds/
│   └── Animations/
└── Tests/
    ├── KuruttoTests/
    └── KuruttoUITests/
```

## 🧪 テスト

ユニットテストの実行:
```bash
xcodebuild test -scheme Kurutto -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📝 ドキュメント

詳細なドキュメントは [specs/phase01](./specs/phase01) ディレクトリを参照してください:

- [00_目次](./specs/phase01/00_目次.md)
- [04_技術仕様書](./specs/phase01/04_技術仕様書.md)
- [07_UI_UX設計](./specs/phase01/07_UI_UX設計.md)
- [10_開発ロードマップ](./specs/phase01/10_開発ロードマップ.md)

## 🤝 コントリビューション

現在、このプロジェクトはプライベート開発中です。

## 📄 ライセンス

Copyright (c) 2025 Kurutto Project. All rights reserved.

## 👥 開発チーム

- iOS Developer: [Your Name]
- UI/UX Designer: [Designer Name]
- Educational Advisor: [Advisor Name]

## 📞 お問い合わせ

質問や提案がある場合は、[issue](https://github.com/yourusername/kurutto/issues) を作成してください。