# flutter_pos

Flutter POS client for the SaaS POS backend.

## API base URL configuration

The app resolves `API_BASE_URL` in this order:

1. `.env` value (`API_BASE_URL=...`)
2. `--dart-define=API_BASE_URL=...`
3. Debug/profile fallback: `http://127.0.0.1:8090`

Release builds require `API_BASE_URL` and will throw if missing.

Example:

```bash
cp .env.example .env
flutter run
```
