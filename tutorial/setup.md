# Setup

Keep the repository root for shared files like `README.md`, `LICENSE`, `.gitignore`, `.github/`, `justfile`, and `tutorial/`.

Put all Flutter code inside a single `workspace/` folder.

This Flutter client talks to the Team Task Board REST API and models anonymous, normal-user, and admin views of public and private tasks.

From the repository root, run each setup command and checkpoint it before moving to the next one:

```bash
rm -rf workspace

mkdir -p workspace

flutter create --platforms=web,android,ios,macos,windows,linux --org com.intrepion --project-name team_task_board workspace
git add --all
git commit --message "flutter create --platforms=web,android,ios,macos,windows,linux --org com.intrepion --project-name team_task_board workspace"

rm workspace/test/widget_test.dart
git add --all
git commit --message "rm workspace/test/widget_test.dart"

(cd workspace && flutter pub add http)
just format
git add --all
git commit --message "(cd workspace && flutter pub add http)"

(cd workspace && flutter pub add --dev test)
just format
git add --all
git commit --message "(cd workspace && flutter pub add --dev test)"

(cd workspace && flutter pub add --dev mocktail)
just format
git add --all
git commit --message "(cd workspace && flutter pub add --dev mocktail)"

(cd workspace && flutter pub add --dev integration_test --sdk flutter)
just format
git add --all
git commit --message "(cd workspace && flutter pub add --dev integration_test --sdk flutter)"
```

Put this exact content in `workspace/macos/Runner/DebugProfile.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>
```

Put this exact content in `workspace/macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

Add this block inside the top-level `<dict>` in `workspace/macos/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
	<key>NSAllowsLocalNetworking</key>
	<true/>
</dict>
```

Then run:

```bash
git add --all
git commit --message "Enable macOS network client entitlement"
```

When the full workspace is finished, it should contain these files:

```text
workspace/
  pubspec.yaml
  lib/
    contracts/
      team_task.dart
      team_task_api.dart
      team_task_list_response.dart
    code/
      team_task_board_controller.dart
    adapter/
      http_team_task_api.dart
      team_task_board_page.dart
  test/
    code/
      team_task_board_controller_test.dart
    adapter/
      http_team_task_api_test.dart
      team_task_board_page_test.dart
  integration_test/
    app_test.dart
  lib/main.dart
```

Before you try any run command, make sure Flutter can see a supported target:

```bash
just devices
```

For web, use the default web command:

```bash
just run
```

or, explicitly:

```bash
just run-web
```

On macOS for iOS, install CocoaPods first if you have not already:

```bash
sudo gem install cocoapods
```

Then open the simulator, list devices, and run the iOS app with an actual simulator id or name:

```bash
open -a Simulator
just devices
just run-ios device="<ios-device-id-or-name>"
```

Flutter does not accept bare `ios` as a generic simulator target, so if `just devices` does not show your simulator yet, wait a moment and run it again.

For Android, list available emulators, launch one, list devices again, and then run the Android app:

```bash
just emulators
flutter emulators --launch <emulator-id>
just devices
just --set api_base_url http://10.0.2.2:25664 run-android device="<android-device-id-or-name>"
```

For macOS desktop, use:

```bash
just run-macos
```

If the macOS desktop app does not appear to reach the API, rerun it with the host URL made explicit:

```bash
just --set api_base_url http://localhost:25664 run-macos
```
For Windows or Linux, run the matching command on that host platform:

```bash
just run-windows
just run-linux
```

After your first successful iOS run, if CocoaPods added shared iOS project files like these:

- `workspace/ios/Runner.xcodeproj/project.pbxproj`
- `workspace/ios/Runner.xcworkspace/contents.xcworkspacedata`
- `workspace/ios/Podfile.lock`

then run:

```bash
git add --all
git commit --message "Add iOS CocoaPods workspace files"
```

After your first successful macOS run, if CocoaPods added shared macOS project files like these:

- `workspace/macos/Runner.xcodeproj/project.pbxproj`
- `workspace/macos/Runner.xcworkspace/contents.xcworkspacedata`
- `workspace/macos/Podfile.lock`

then run:

```bash
git add --all
git commit --message "Add macOS CocoaPods workspace files"
```

Do not commit local machine output like these:

- `workspace/ios/Pods/`
- `workspace/macos/Pods/`
- `workspace/build/`
- `workspace/.dart_tool/`

For Android, a normal first run usually should not add shared tracked files. If it does change shared files under `workspace/android/`, review them carefully and commit only the project-level changes. Do not commit machine-specific files like:

- `workspace/android/local.properties`
- `workspace/.gradle/`
- `workspace/build/`
