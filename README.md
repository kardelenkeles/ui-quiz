# ui-quiz

## Production configuration

Runtime/build values are supplied with Dart defines. Copy
`config/production.example.json` to `config/production.json`, enter the iOS
RevenueCat public SDK key, and keep that local file out of Git.

```sh
flutter build appbundle --release \
  --dart-define-from-file=config/production.json

flutter build ios --release \
  --dart-define-from-file=config/production.json
```

Release builds require the RevenueCat SDK key for the target platform. They
also reject non-HTTPS and localhost backend/auth URLs. RevenueCat debug logs
are enabled only outside production.

Firebase email-link authentication uses
`https://quiz-ai-242b4.firebaseapp.com`. Keep this domain in Firebase Auth's
authorized-domain list. If a custom Firebase Hosting domain is introduced,
set `AUTH_LINK_DOMAIN` and update both Android's intent-filter host and iOS's
Associated Domains entitlement to the same host.

## Tests

```sh
# Flutter unit and widget tests
flutter test

# Device/emulator integration smoke test
flutter test integration_test/production_config_test.dart -d DEVICE_ID

# Cloud Functions unit tests
cd functions && npm test
```

The Flutter suite covers authentication persistence, quota authorization,
quiz generation and deduplication, document extraction, and purchase UI/service
behavior. Cloud Functions tests cover request validation, quota helpers, and
RevenueCat webhook signature verification.
