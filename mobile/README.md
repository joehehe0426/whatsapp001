## Mobile mock chat history app

This folder contains a **local-only** mobile app for creating and viewing **mock chat history** (for demos, UX, screenshots, etc.).

It **does not connect to WhatsApp** and is **not affiliated** with WhatsApp/Meta.

### Run

This repo currently includes the Dart/Flutter app code (`lib/`, `pubspec.yaml`), but it does not include the generated platform folders (`android/`, `ios/`) because Flutter tooling isn't vendored here.

To run it, create a Flutter app skeleton and copy this app code in:

```bash
# 1) Create a fresh Flutter app somewhere
flutter create --platforms=android,ios chat_history_mock
cd chat_history_mock

# 2) Copy this repo's app code in
rsync -a --delete /path/to/this/repo/mobile/lib/ ./lib/

# 3) Add deps from this repo's pubspec.yaml (intl, path_provider, uuid)
#    then:
flutter pub get
flutter run
```

If you already have a Flutter app skeleton in `mobile/`, you can instead run from the `mobile/` directory:

```bash
flutter pub get && flutter run
```

### Features

- Chat list UI (recent chats, unread badge)
- Chat view with message bubbles
- Compose messages as "me" or "them"
- Create/rename chats
- Import/export history as JSON (copy/paste)

### Data storage

The app stores history as a single JSON file in the app documents directory:

- `chat_history_mock.json`

