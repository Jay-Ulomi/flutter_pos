# flutter_pos

Flutter POS client for the SaaS POS backend.

## Configuration

Settings are compile-time values (`String.fromEnvironment`). Keep them in a
local `.env` (gitignored) and pass it to every run/build:

```bash
cp .env.example .env          # then edit the URLs if needed
flutter run --dart-define-from-file=.env
flutter build apk --dart-define-from-file=.env
```

| Key | Purpose |
|---|---|
| `API_BASE_URL` | Backend base URL (the app adds `/api/...`) |
| `BUSINESS_ADMIN_URL` | Business Admin web app, for billing and password-reset links |

Single values also work: `--dart-define=API_BASE_URL=https://your-host`.

Without a value, debug/profile builds fall back to `http://127.0.0.1:8090`
(and `http://127.0.0.1:5175` for Business Admin); **release builds throw** if
`API_BASE_URL` is missing, so never ship a build made without the file.

`.env` is not bundled as an asset any more, so a fresh clone builds and
`flutter test` runs without one.

## Look and brand (Aduinola redesign)

- Theme: `lib/core/theme/app_theme.dart` (pill inputs/buttons, rounded cards,
  light/dark) and `brand_colors.dart`; the `AppDecor` extension holds the
  background gradient and status-pill colours. Shared widgets live in
  `lib/presentation/widgets/aduinola/`.
- Font: Outfit (OFL, `assets/fonts/`), bundled so it works offline.
- New-screen copy is English/Swahili in `lib/core/l10n/app_strings.dart`
  (`context.tr('key')`); older screens are still English only.
- App Settings (theme, text size, language, formats, currency, privacy mode,
  app lock) are stored on the device only. The app-lock PIN is kept as a
  salted PBKDF2 hash in secure storage.

### Launcher icon and native splash

Configs are in `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`.
The generators are not dev dependencies, so run them as global tools:

```bash
dart pub global activate flutter_launcher_icons 0.14.3
dart pub global run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart pub global activate flutter_native_splash 2.4.4
dart pub global run flutter_native_splash:create --path=flutter_native_splash.yaml
```

Commit the generated platform files afterwards.
