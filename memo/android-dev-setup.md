# Android開発環境 - セットアップと日常使用手順

## 環境情報
- OS: WSL2 Ubuntu
- Flutter SDK: 3.32.2
- Android SDK: 34.0.0
- Android Studio: 2024.2
- エミュレーター: Flutter_Android_34 (Android 14, API 34)

## 初回セットアップ（完了済み）
以下は既に完了している設定です：

### 1. Android Studio インストール
```bash
# Android Studioダウンロード・インストール（完了済み）
sudo mv android-studio /opt/
```

### 2. 権限設定
```bash
# KVMグループにユーザー追加（完了済み）
sudo gpasswd -a $USER kvm
```

### 3. AVD作成
```bash
# システムイメージインストール（完了済み）
~/usr/android-sdk/cmdline-tools/latest/bin/sdkmanager "system-images;android-34;google_apis_playstore;x86_64"

# AVD作成（完了済み）
echo "no" | ~/usr/android-sdk/cmdline-tools/latest/bin/avdmanager create avd --name "Flutter_Android_34" --package "system-images;android-34;google_apis_playstore;x86_64" --device "pixel_3a"
```

## 日常の開発手順

### 1. 新しいシェルセッションでの権限設定
新しいターミナルを開くたびに以下を実行：

```bash
# KVMグループをアクティブにする
newgrp kvm

# XDG_RUNTIME_DIR環境変数を設定
export XDG_RUNTIME_DIR=/run/user/1000
```

### 2. Androidエミュレーターの起動

#### GUIウィンドウ付きで起動（推奨）
```bash
~/usr/android-sdk/emulator/emulator -avd Flutter_Android_34 -gpu swiftshader_indirect -no-snapshot -no-audio &
```

#### ヘッドレスモード（GUIなし）で起動
```bash
~/usr/android-sdk/emulator/emulator -avd Flutter_Android_34 -gpu swiftshader_indirect -no-snapshot -no-audio -no-window &
```

### 3. エミュレーター接続確認
```bash
# エミュレーターの起動状況確認
flutter devices

# ADBでデバイス確認
~/usr/android-sdk/platform-tools/adb devices
```

### 4. Flutterアプリの実行
```bash
# frontディレクトリに移動
cd front

# エミュレーターでアプリを実行
flutter run -d emulator-5554
```

### 5. エミュレーターの終了
```bash
# エミュレーターを終了
~/usr/android-sdk/platform-tools/adb -e emu kill
```

## トラブルシューティング

### エミュレーターが起動しない場合
1. 権限設定を再確認：
```bash
groups  # kvmが表示されることを確認
echo $XDG_RUNTIME_DIR  # /run/user/1000が表示されることを確認
```

2. プロセス確認：
```bash
ps aux | grep emulator
```

3. エミュレーター強制終了：
```bash
pkill -f emulator
```

### Flutterが認識しない場合
```bash
# Flutter環境確認
flutter doctor

# デバイス再確認
flutter devices --device-timeout 30
```

## 利用可能なエミュレーター
```bash
# エミュレーター一覧表示
flutter emulators

# 利用可能なエミュレーター:
# - Flutter_Android_34 (Android 14, API 34)
# - Medium_Phone_API_36 (Medium Phone API 36)
```

## よく使用するコマンド
```bash
# Flutter環境確認
flutter doctor

# エミュレーター一覧
flutter emulators

# デバイス一覧
flutter devices

# アプリ実行（ホットリロード対応）
flutter run

# アプリのビルド（APK作成）
flutter build apk

# アプリのビルド（リリース版）
flutter build apk --release
```

## 注意事項
- WSL2環境では、エミュレーターの起動に時間がかかる場合があります（1-2分程度）
- 新しいシェルセッションでは必ず `newgrp kvm` と `export XDG_RUNTIME_DIR=/run/user/1000` を実行してください
- エミュレーターは複数起動できますが、リソース使用量に注意してください 