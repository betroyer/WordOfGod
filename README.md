# FaithPath — Bible Study & Companion

Flutter Bible app with offline Scripture study tools and an **online AI Bible Assistant** (Groq free tier by default).

## How it works

- **Bible reading, search, journals, plans** — work offline on your device
- **AI Bible Assistant** — requires internet + a [Groq](https://console.groq.com) API key

## Stack

- Flutter + Dart · Riverpod · Drift/SQLite · GoRouter · Dio · connectivity_plus

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

### AI setup (Groq)

Defaults are already set to Groq:

- Base URL: `https://api.groq.com/openai/v1`
- Model: `llama-3.3-70b-versatile`

> Note: `llama-3.1-8b-instant` was retired by Groq on 2026-08-16.

1. Create a free key at https://console.groq.com/keys
2. In the app: **Settings → AI Assistant → API key** (paste `gsk_...`)
3. Or put it in gitignored `lib/core/secrets/ai_secrets.dart`
4. Connect to Wi‑Fi / mobile data and open **Ask AI**

## GitHub

https://github.com/betroyer/WordOfGod
