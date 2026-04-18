# Finish

Make sure the matching Team Task Board API is running on your development machine at port `25664`.

For web, start the Flutter app from the repository root with:

```bash
just run
```

or:

```bash
just run-web
```

Then open `http://localhost:25616` in your browser.

For iOS, open the simulator, list devices, and run with an actual simulator id or name:

```bash
open -a Simulator
just devices
just run-ios device="<ios-device-id-or-name>"
```

For Android, use:

```bash
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

After the first successful iOS run, if CocoaPods added shared iOS project files like these:

- `workspace/ios/Runner.xcodeproj/project.pbxproj`
- `workspace/ios/Runner.xcworkspace/contents.xcworkspacedata`
- `workspace/ios/Podfile.lock`

then run:

```bash
git add --all
git commit --message "Add iOS CocoaPods workspace files"
```

After the first successful macOS run, if CocoaPods added shared macOS project files like these:

- `workspace/macos/Runner.xcodeproj/project.pbxproj`
- `workspace/macos/Runner.xcworkspace/contents.xcworkspacedata`
- `workspace/macos/Podfile.lock`

then run:

```bash
git add --all
git commit --message "Add macOS CocoaPods workspace files"
```

A normal Android run usually should not add shared tracked files. Do not commit machine-specific files like `workspace/android/local.properties`, `workspace/.gradle/`, `workspace/build/`, or `workspace/macos/Pods/`.

Try this flow:

- load the board as `anonymous` and confirm you only see public tasks
- switch to `user` with `user-alice` and load again to reveal Alice's private tasks
- add a new `public` task for `user-alice`
- switch to `admin` with `user-admin` and remove a task

If the API is unavailable, the app should show `Sorry, the team task API is unavailable right now.`
