# Fieldbook

A farm journal for the working day. Flutter client, Django REST API, PostgreSQL.

The first-month MVP covers accounts, shared farms and fields, crop reference data,
planting cycles, cultivation and harvest records, weather, and a dashboard.
Disease/yield prediction, a chatbot, and advanced expert workflows are deferred.

## Development

Implementation is in progress on feature branches. Each completed feature is
tested before its local merge into `main`; no GitHub remote is configured.

Backend: Python 3.14 / Django 6.1.2. Frontend: Flutter 3.47.6.
Secrets belong in `backend/.env`, which is ignored by Git.

See [CHANGELOG.md](CHANGELOG.md) for completed milestones.

## Local setup (Windows)

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv\Scripts\python.exe scripts/init_local.py
.\.venv\Scripts\python.exe backend/manage.py migrate
.\.venv\Scripts\python.exe backend/manage.py runserver 127.0.0.1:8000
```

`init_local.py` creates an ignored `.env` with random application/admin secrets
and the local database connection specified for this project. It never overwrites
an existing `.env` or database. PostgreSQL must already be running.

In another terminal:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080
```

Use `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/` for an Android
emulator. A physical phone needs the computer's LAN address, a server bound to
`0.0.0.0:8000`, and that address in `DJANGO_ALLOWED_HOSTS`.

## Verification

```powershell
.\.venv\Scripts\python.exe backend/manage.py test --noinput
cd frontend
flutter analyze
flutter test
# Requires the local backend running:
flutter test --dart-define=RUN_LIVE_API_TESTS=true test/live_api_test.dart
```

See [PROGRESS.md](PROGRESS.md) for checks actually executed and pending work.
