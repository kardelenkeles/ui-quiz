# PomeAI Quiz

PomeAI Quiz; metin, belge ve görsellerden yapay zekâ destekli quiz oluşturan
Flutter uygulamasıdır. Mobil istemci Firebase Authentication, Firestore,
Realtime Database, RevenueCat ve Firebase Cloud Functions tabanlı OpenAI proxy
ile çalışır. Web hedefi de derlenebilir ve dosya işlemleri byte/XFile tabanlıdır.

## Gereksinimler

- Flutter stable ve Dart 3.9+
- Node.js 22 (Cloud Functions)
- Firebase CLI (yalnızca emulator/deploy için)
- iOS için güncel Xcode/CocoaPods, Android için güncel Android SDK

## Yerel kurulum

```sh
flutter pub get
cd functions && npm ci && cd ..
flutter run
```

Firebase istemci ayarları `lib/firebase_options.dart`, Android
`google-services.json` ve iOS `GoogleService-Info.plist` dosyalarında tutulur.
OpenAI ve RevenueCat webhook gizli değerleri istemciye konmaz; Firebase/Google
Secret Manager üzerinden Cloud Functions'a verilir.

## Ortam ve üretim yapılandırması

`config/production.example.json` dosyasını Git'e alınmayan
`config/production.json` adıyla kopyalayın. Boş iOS RevenueCat anahtarını gerçek
public SDK anahtarıyla doldurun.

```sh
flutter build appbundle --release \
  --dart-define-from-file=config/production.json

flutter build ios --release \
  --dart-define-from-file=config/production.json
```

Desteklenen define değerleri:

- `APP_ENV`: `development`, `staging` veya `production`
- `API_BASE_URL`: Cloud Functions API kökü
- `AUTH_CONTINUE_URL`: e-posta giriş linkinin dönüş adresi
- `AUTH_LINK_DOMAIN`: yalnızca özel Firebase Hosting domain'i kullanılıyorsa
- `REVENUECAT_ANDROID_API_KEY` / `REVENUECAT_IOS_API_KEY`: public SDK anahtarları

Üretim modu HTTP/localhost URL'lerini ve hedef platformun boş RevenueCat
anahtarını başlangıçta reddeder. RevenueCat debug logları yalnızca üretim dışı
derlemelerde açıktır.

E-posta linkleri `https://quiz-ai-242b4.firebaseapp.com/finishSignIn` adresini
kullanır. Domain Firebase Auth yetkili domain listesinde bulunmalıdır. Özel bir
domain'e geçerken define değerini, Android intent filter'ını ve iOS Associated
Domains entitlement'ını birlikte güncelleyin.

## Mimari

- `lib/providers`: ekran durumları ve akış koordinasyonu
- `lib/services`: auth, kota, AI proxy, dosya çıkarma, satın alma ve depolama
- `lib/core`: merkezi loglama ve kullanıcı dostu hata eşleme
- `lib/screens`: ekranlar; quiz generator görünümü ayrı bir `part` dosyasındadır
- `functions`: doğrulama, kota, rate-limit, OpenAI proxy ve RevenueCat webhook
- `test` / `integration_test`: unit, widget ve cihaz smoke testleri

## Kalite kontrolleri

```sh
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run \
  --dart-define=APP_ENV=staging

cd functions
npm test
node --check index.js
```

Cihaz/emülatör üretim yapılandırması smoke testi:

```sh
flutter test integration_test/production_config_test.dart -d DEVICE_ID
```

Testler auth kalıcılığı, kota yetkilendirmesi, quiz üretimi/deduplication,
TXT-DOCX-PPTX-XLSX çıkarma ve satın alma akışlarını kapsar. GitHub Actions her
PR ve `main` push'unda strict analyze, Flutter testleri, web release derlemesi,
Functions testleri ve JavaScript sözdizimi kontrolünü çalıştırır.

## Monitoring ve hata yönetimi

`AppLogger` uygulama loglarını merkezileştirir. Yakalanan hatalar teknik ayrıntı
yerine `AppErrorHandler` üzerinden güvenli Türkçe kullanıcı mesajlarına çevrilir.
Android/iOS üzerinde Flutter framework ve yakalanmamış async hatalar Firebase
Crashlytics'e gönderilir; web ve desteklenmeyen masaüstü hedeflerinde Crashlytics
çağrısı yapılmaz. Firebase projesinde Google Analytics açık olduğunda
Crashlytics breadcrumb bilgileri de toplanır.

İlk yayından önce gerçek cihazda bir test hatası gönderip Firebase Crashlytics
panelinde göründüğünü doğrulayın. Obfuscation/`--split-debug-info` kullanılırsa
release sembollerini Firebase'e yükleme adımını pipeline'a ekleyin.

## Deployment

`.github/workflows/deploy-backend.yml` yalnızca manuel çalıştırmada veya GitHub
Release yayımlandığında devreye girer. Önce Functions testleri geçer, ardından
`production` environment onayıyla Functions ve güvenlik kuralları birlikte
deploy edilir.

Repository ayarlarında şunlar gereklidir:

1. `production` environment ve tercihen zorunlu reviewer.
2. En az yetkili servis hesabının JSON içeriğini taşıyan
   `FIREBASE_SERVICE_ACCOUNT` secret'ı.
3. Firebase/Secret Manager tarafında `OPENAI_SECRET`,
   `REVENUECAT_WEBHOOK_SECRET` ve `REVENUECAT_WEBHOOK_SIGNING_SECRET`.

Backend ayrıntıları ve endpointler için `functions/README.md` dosyasına bakın.
