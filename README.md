# FaithPath — Bible Study & Companion

Flutter Bible app with offline Scripture study tools and an **online AI Bible Assistant**.

## How it works

- **Bible reading, search, journals, plans** — work offline on your device
- **AI Bible Assistant** — requires internet + an API key (OpenAI-compatible)

## Stack

- Flutter + Dart · Riverpod · Drift/SQLite · GoRouter · Dio · connectivity_plus

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

### AI with internet

1. Open **Settings → AI Assistant**
2. Keep **Enable AI** on (default)
3. Paste your OpenAI-compatible API key
4. Connect to Wi‑Fi / mobile data
5. Open **Ask AI** from Home or a verse

Or pass a key at launch:

```bash
flutter run --dart-define=FAITHPATH_AI_API_KEY=sk-your-key
```

## GitHub

https://github.com/betroyer/WordOfGod
