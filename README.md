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
