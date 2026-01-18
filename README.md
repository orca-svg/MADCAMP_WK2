# frontend

Retro radio Flutter app with login, sign up, and a daily comfort message.

## Hot reload vs hot restart vs rebuild

- Hot reload updates running UI and logic, keeping app state. Use this for most UI tweaks.
- Hot restart restarts the app and resets state, but is faster than a full rebuild.
- Rebuilds are needed when you change native code or add assets in `pubspec.yaml`.

If you add or change asset paths, run `flutter pub get` and then hot restart so
the new assets are registered.

## App icon
1) Place the icon at `assets/icon/app_icon.png`.
2) Ensure `flutter_launcher_icons` is configured in `pubspec.yaml`.
3) Run `flutter pub get`.
4) Run `dart run flutter_launcher_icons`.
