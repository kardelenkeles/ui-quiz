# Firebase Functions (api)

Bu dosya `functions` klasöründeki OpenAI proxy fonksiyonu için hızlı kurulum, secret yönetimi ve test adımlarını içerir.

Özet
- Fonksiyon: `api` (Gen2, Node.js 22)
- Entry point: `/` (HTTP trigger)
- Önemli endpointler:
  - `GET /health` — fonksiyonun durumu ve API anahtarı var mı bilgisini döner
  - `GET /quota` — (auth required) sunucu tarafındaki kota bilgisini döner
  - `GET /openai/models` — (auth required) yalnızca izin verilen modelleri listeler
  - `POST /openai/chat` — (auth required) doğrulama, kota ve hız limiti uygulayan OpenAI proxy
  - `POST /revenuecat/webhook` — RevenueCat tarafından doğrulanmış premium durumunu günceller

API anahtarı hiçbir endpoint tarafından istemciye döndürülmez. Model seçimi,
çıktı token sınırı, istek boyutu, kullanıcı kotası ve dakika başına istek sınırı
sunucuda uygulanır.

Gizli anahtarın saklanması (önerilen)
1. Secret Manager kullanın (önerilir). Örnek: `openai-api-key` isimli secret oluşturun ve anahtarı ekleyin.

  ```pwsh
  # Secret oluşturma
  gcloud secrets create openai-api-key --replication-policy="automatic" --project=quiz-ai-242b4

  # Secret'e değer ekleme
  echo "YOUR_OPENAI_API_KEY" | gcloud secrets versions add openai-api-key --data-file=- --project=quiz-ai-242b4
  ```

2. Fonksiyon deploy ederken environment variable ile secret referansını ekleyin:

  ```pwsh
  gcloud functions deploy api --gen2 --runtime=nodejs22 --region=us-central1 \
    --entry-point=api --trigger-http --project=quiz-ai-242b4 \
    --set-env-vars=OPENAI_SECRET=projects/quiz-ai-242b4/secrets/openai-api-key/versions/latest,REVENUECAT_WEBHOOK_SECRET=YOUR_RANDOM_WEBHOOK_SECRET,REVENUECAT_WEBHOOK_SIGNING_SECRET=YOUR_HMAC_SIGNING_SECRET \
    --allow-unauthenticated
  ```

3. Fonksiyonun çalıştığı servis hesabına Secret Manager erişimini verin:

  ```pwsh
  gcloud projects add-iam-policy-binding quiz-ai-242b4 \
    --member=serviceAccount:1005130341735-compute@developer.gserviceaccount.com \
    --role=roles/secretmanager.secretAccessor
  ```

Alternatif: `functions.config()`
- Kısa süreli test için `firebase functions:config:set openai.key="YOUR_KEY"` kullanabilirsiniz, ancak `functions.config` uzun vadede deprecte oluyor. Secret Manager önerilir.

Deploy notları
- Node 22 runtime kullanılır; bu runtime global `fetch` içerir.
- `package.json` içindeki bağımlılıkları güncel tutun; build sırasında sürüm uyuşmazlıkları çıkarsa dinamik import teknikleri kullanılabilir.
- HTTP fonksiyonu Cloud Run seviyesinde erişilebilir kalır; korunan endpointler Firebase ID token doğrulamasını uygulama katmanında yapar.
- RevenueCat webhook Authorization başlığını `Bearer REVENUECAT_WEBHOOK_SECRET` olacak şekilde yapılandırın ve HMAC imzalamayı `REVENUECAT_WEBHOOK_SIGNING_SECRET` ile etkinleştirin.
- RevenueCat entitlement kimliği kodda `pro` olarak beklenir.
- `firebase deploy --only firestore:rules,database,functions` ile kuralları ve fonksiyonu birlikte yayınlayın.

Test (PowerShell örnekleri)
- /health (anonim erişim açıksa çalışır):
  ```pwsh
  curl -s https://us-central1-quiz-ai-242b4.cloudfunctions.net/api/health | ConvertFrom-Json
  ```

- /openai/models (auth required):
  ```pwsh
  $idToken = "<FIREBASE_ID_TOKEN>"
  curl -s -H "Authorization: Bearer $idToken" https://us-central1-quiz-ai-242b4.cloudfunctions.net/api/openai/models
  ```

- /openai/chat (auth required):
  ```pwsh
  $idToken = "<FIREBASE_ID_TOKEN>"
  $body = '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Merhaba"}]}'
  curl -s -H "Authorization: Bearer $idToken" -H "Content-Type: application/json" -d $body https://us-central1-quiz-ai-242b4.cloudfunctions.net/api/openai/chat
  ```

Sorun giderme
- Eğer `/health` `hasApiKey: false` dönerse:
  - Secret Manager'da secret'ın gerçekten var olduğunu ve içeriğinin doğru olduğunu doğrulayın.
  - Servis hesabına (`1005130341735-compute@developer.gserviceaccount.com`) `roles/secretmanager.secretAccessor` verildiğini doğrulayın.
- Eğer deploy sırasında `Cannot find module '@google-cloud/secret-manager'` gibi hata görürseniz `package.json`'a uygun sürümü ekleyip `npm install` yapın; ya da kodun dinamik import yolunu kullanın.

İletişim
- Test sonuçlarını gönderin, hatayla karşılaşırsanız logları alıp yardımcı olurum.
