# AR Smart Study AI Backend

This backend keeps the OpenAI API key on the server and exposes a small API
for the Flutter app.

## Run locally

```bash
export OPENAI_API_KEY="your_openai_key"
npm start
```

Optional model override:

```bash
export OPENAI_MODEL="gpt-5.4-mini"
```

Health check:

```bash
curl http://localhost:8787/health
```

AI endpoint:

```bash
curl -X POST http://localhost:8787/ai \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Қазақ тілінде қысқаша түсіндір"}'
```

## Build Flutter APK with the backend

Use the public deployed server URL:

```bash
flutter build apk --release \
  --dart-define=AI_BACKEND_URL=https://your-domain.example/ai
```
