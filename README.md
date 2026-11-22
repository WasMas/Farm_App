# Fieldbook

A working farm journal, built with **Django 6.1.2 + DRF + PostgreSQL** and
**Flutter 3.47.6 / Dart 3.13.5**. Olive, soil, wheat and warm paper; bundled Lora
and DM Sans typography; a field illustration drawn in Flutter.

## First-month MVP

- Registration, JWT login/refresh/logout, protected navigation and secure token storage.
- Administrator, owner and worker roles; Django groups; farm membership permissions.
- Farm/field CRUD, coordinates, decimal hectares and combined-area validation.
- Shared farm access: owner, manager, worker and viewer responsibilities.
- Admin-managed crop catalogue; planting cycles, varieties, stages and completed seasons.
- Irrigation, fertilization, treatments, observations and harvest records with dates/units.
- Searchable activity history, protected historical relationships and admin audit records.
- A dashboard calculated from stored records, with consistent water/harvest units.
- Open-Meteo weather, optional encrypted customer keys, and `--` for unavailable values.
- Responsive desktop/phone layouts and saved daylight/dark/device appearance.

Disease/yield prediction, a chatbot, advanced expert review and offline sync are
intentionally deferred. See [PROGRESS.md](PROGRESS.md) for actual verification
results and platform limitations; [CHANGELOG.md](CHANGELOG.md) for milestones.

## Start the backend

Starting on a computer with no development tools installed? Follow
[SETUP.md](SETUP.md) for the complete Windows installation and first-run guide.

PostgreSQL must be running. The local `backend/.env` is already configured in
this workspace with the database details supplied for the project. It is ignored
by Git. For a fresh checkout, initialize it as follows:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv\Scripts\python.exe scripts/init_local.py
```

The initializer asks for the PostgreSQL password, generates random application
and initial-admin secrets, and creates the database only if it is absent. To
change the database username/host/name, edit `backend/.env` before running it.
The committed `.env.example` contains names and placeholders, never credentials.

```powershell
.\.venv\Scripts\python.exe scripts/run_backend.py 127.0.0.1:8000
```

Every startup applies migrations and invokes `ensure_admin` before starting
Django. The command creates one administrator only when no active administrator
exists. It validates the configured password, handles concurrent startup safely,
and leaves existing accounts/passwords untouched. Identity conflicts require
choosing another configured identity rather than silently promoting an account.

The initial username/password are in `backend/.env` under `INITIAL_ADMIN_*`.
Django Admin: **http://127.0.0.1:8000/admin/**. It manages accounts, roles,
reference data and audit records. Administrators provision owner accounts.

## Start Flutter

A built preview may already be running at **http://127.0.0.1:8080/** in the
current workspace, with Django on port 8000. Use that preview directly. For a
new hot-reload session, stop the existing static server first, or use another
web port and add its origin to `CORS_ALLOWED_ORIGINS`.

```powershell
cd frontend
flutter pub get
flutter run -d edge --web-port 8080
```

Default API: `http://localhost:8000/api/`. CORS allows localhost/127.0.0.1 on port
8080. If Flutter is not on PATH, call your SDK at
`C:\Portable\Develop\Flutter-3.47.6\bin\flutter.bat`.
Edge is installed on this computer. Chrome can also be used once installed.

For an Android emulator:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/
```

For a physical phone, start Django with `0.0.0.0:8000`, add the computer's LAN
address to `DJANGO_ALLOWED_HOSTS` in `.env`, and pass that address through
`API_BASE_URL`. Allow the development port on your private network if necessary.
Android debug builds permit local HTTP; release builds should use an HTTPS API.
For the web client on a phone, use HTTPS because browser secure storage requires
a secure context (localhost is an exception).

Native desktop: `flutter run -d windows` (or `macos`/`linux` on those systems).
Windows currently needs Developer Mode/symlink support enabled; a native Windows
build was attempted and stopped at that prerequisite. Visual Studio C++/ATL
tools are also required by the storage plugin. iOS/macOS need their normal
Apple build/signing tools. Linux needs the storage plugin's libsecret/jsoncpp
development libraries. Those targets have source scaffolds, not verified release
packages. No physical-device runtime test has been performed.

An Android debug APK was built successfully at
`frontend/build/app/outputs/flutter-apk/app-debug.apk`, configured for the emulator
address above. Build artifacts are ignored by Git. For another address, rebuild:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://YOUR-LAN-IP:8000/api/
```

Kotlin incremental compilation is disabled in the Android project because this
workspace is on D: and the Pub cache is on C:, which triggered a cross-drive
path-cache failure during verification. This is a build-performance tradeoff.

## First use

1. Register a farmer or sign in with the initial administrator.
2. Add a farm and its total area. Coordinates are optional until using weather.
3. Add fields whose combined area fits the farm.
4. Create a planting from the crop catalogue and allocate its field area.
5. Record work and observations in **Day’s work**. A harvest is an actual event.
6. Visit **The journal** for totals and recent history.
7. Open **Weather → Weather settings → Connected**. Choose the public API
   without a key, or customer mode with a customer key.

Weather is disconnected initially. Missing coordinates, a missing required key,
provider errors, and absent individual readings display `--`. A zero reading
displays zero. Successful snapshots are cached for ten minutes; refresh fetches
again. Keys are never returned to Flutter after saving.

## Tests

From the repository root:

```powershell
.\.venv\Scripts\python.exe scripts/test_backend.py
.\.venv\Scripts\python.exe backend/manage.py makemigrations --check --dry-run
.\.venv\Scripts\python.exe scripts/verify_live.py
```

The backend test wrapper runs discovery from `backend/`; running an unlabelled
`manage.py test` from the repository root otherwise discovers no Django tests.
The live runner creates a uniquely named PostgreSQL test database, applies the
real migrations, starts a local Django instance, runs all Flutter HTTP repository
tests, then terminates that instance and removes only its own test database.
It does not populate or erase `farm_app`. PostgreSQL must permit test DB creation.
Set `FLUTTER_ROOT` if your SDK is installed somewhere else.

```powershell
cd frontend
flutter analyze
flutter test
```

Live API tests are skipped in the ordinary widget suite and run by the separate
live runner. Provider connectivity is reported explicitly by the weather live
test. Widget tests cover phone/desktop layouts, navigation, form validation,
filtering, logout and preferences. They are separate from a browser/device test.
The browser tool was unavailable in this environment, so no manual browser
click-through is claimed.

To regenerate local visual previews using fixture data:

```powershell
flutter test --dart-define=CAPTURE_PREVIEWS=true test/visual_preview_test.dart
```

Previews are saved under ignored `.local/previews/`. If the Windows PowerShell
launcher fails in a restricted runner, the installed Flutter tool can also be
invoked through Dart:

```powershell
& 'C:\Portable\Develop\Flutter-3.47.6\bin\cache\dart-sdk\bin\dart.exe' `
  'C:\Portable\Develop\Flutter-3.47.6\bin\cache\flutter_tools.snapshot' analyze --no-pub
```

## Structure and diagrams

```text
backend/   config, accounts, farms, crops, activities, weather, dashboard, core
frontend/  lib/core and lib/features/<feature>/{domain,data,presentation}
scripts/   local initialization, startup, tests and font-source downloader
docs/      architecture and corrected UML sources
```

Read [architecture.md](docs/architecture.md),
[class-diagram.puml](docs/class-diagram.puml) and
[use-cases.puml](docs/use-cases.puml). The UML sources describe the implemented
MVP and can be rendered with PlantUML. Weather data comes from
[Open-Meteo](https://open-meteo.com/en/docs); bundled font licenses are in
`frontend/assets/fonts/`.

## Git workflow

`main` contains locally merged, tested features. Feature branches are retained:
`feat/project-setup`, `feat/authentication`, `feat/farm-management`,
`feat/crop-management`, `feat/activity-tracking`, `feat/weather`, `feat/dashboard`,
and `feat/responsive-ui`. Conventional Commits were created during development.
No GitHub remote was configured, so merges are local and no PRs were published.

Local configuration, tokens, secrets, caches, virtual environments, generated
registrants, build output and previews are excluded from Git.

For the November validation, see the [live demo guide](docs/quality/DEMO.md) and [quality evidence](docs/quality/traceability.md).
