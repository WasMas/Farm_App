# Fieldbook: setup from scratch on Windows

Follow this guide to run the project locally on a Windows computer. The first
setup uses Microsoft Edge for the Flutter interface and PostgreSQL for Django.
An internet connection is needed to download tools and dependencies.

Commands below use **PowerShell** and assume the project is saved in
`C:\Projects\Farm_App`. Change that path if you put the project somewhere else.

## 1. Install the required tools

| Tool | What to install | Purpose |
| --- | --- | --- |
| Git | [Git for Windows](https://git-scm.com/install/windows) | Required by Flutter; also manages project history. |
| Python | [Python 3.14.8, Windows 64-bit installer](https://www.python.org/downloads/windows/) | Runs the Django backend. This is the Python version used during project verification. |
| PostgreSQL | [PostgreSQL Windows installer](https://www.postgresql.org/download/windows/) | Runs the database server. Install the server component; pgAdmin is optional. |
| Flutter | [Flutter 3.47.6 for Windows](https://docs.flutter.dev/install/archive) | Runs the frontend. This project uses Dart 3.13.5, supplied by this Flutter SDK. |
| Browser | Microsoft Edge | Opens the Flutter web app. |

### Python

During installation, enable **Add Python to PATH**. Use Python 3.14.8 to match
the environment in which the project was verified.

### PostgreSQL

During installation:

1. Install the PostgreSQL server.
2. Keep the default username, `postgres`.
3. Choose a password and remember it; the setup script will ask for it.
4. Keep port `5432`.
5. Finish installation and ensure the PostgreSQL Windows service is running.

You do not need to create `farm_app` or its tables manually. The project scripts
create the database and apply the existing Django migrations.

### Flutter

1. Download the Windows SDK archive for **3.47.6**.
2. Extract it so that `flutter.bat` is at `C:\develop\flutter\bin\flutter.bat`.
3. Open Windows **Environment Variables**.
4. Under your user variables, edit **Path** and add `C:\develop\flutter\bin`.
5. Close and reopen PowerShell and your editor.

Use a folder you can write to, without spaces in its path. See the official
[Flutter installation guide](https://docs.flutter.dev/install/manual) for details.
Dart is included with Flutter. Django is installed through the project requirements
in step 3.

### Check the installations

Open a new PowerShell terminal:

```powershell
git --version
python --version
flutter --version
flutter doctor
flutter devices
```

Confirm that Python reports `3.14.8`, Flutter reports `3.47.6`, and Edge appears
in the device list. Android and native Windows toolchains are additional setup
options; this guide first runs the web target.

## 2. Get the project source

Extract a source archive or copy the project source into:

```text
C:\Projects\Farm_App
```

This folder must contain:

```text
Farm_App/
  backend/
    requirements.txt
    .env.example
  frontend/
    pubspec.yaml
  scripts/
    init_local.py
    run_backend.py
  README.md
```

There is currently no configured GitHub remote. If the project is published
later, clone its actual repository URL instead of copying the source.

Each computer needs its own configuration and dependencies. Leave the original
computer's `.env`, `.venv`, build folders and caches out of the source copy.
The font files are already bundled in `frontend/assets/fonts/`.

## 3. Install backend dependencies

In PowerShell, run:

```powershell
cd C:\Projects\Farm_App
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```

Wait for installation to finish successfully before continuing. The requirements
include Django 6.1.2, Django REST Framework and the PostgreSQL driver.

These commands use the virtual environment's Python directly, so you do not need
to activate it or change PowerShell's script execution policy.

## 4. Create local configuration and the database

Ensure PostgreSQL is running, then run from the project root:

```powershell
.\.venv\Scripts\python.exe scripts\init_local.py
```

Enter the password you chose for the PostgreSQL `postgres` user. Password input
is hidden; press Enter after typing it.

The initializer:

- Creates the ignored `backend/.env` file from `.env.example`.
- Saves the PostgreSQL connection details locally.
- Generates a Django secret key and an initial administrator password.
- Creates `farm_app` if it does not exist.

It preserves an existing `.env` and database. For the standard installation,
the connection settings are:

```dotenv
DB_NAME=farm_app
DB_USER=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
```

If your PostgreSQL username, password, host or port differs, edit those values
in `backend/.env` and run the initializer again. Keep the generated
`DJANGO_SECRET_KEY` and `INITIAL_ADMIN_PASSWORD` values. Do not commit `.env`.

## 5. Start the backend: terminal 1

From the project root:

```powershell
cd C:\Projects\Farm_App
.\.venv\Scripts\python.exe scripts\run_backend.py 127.0.0.1:8000
```

The startup script applies migrations, ensures an initial administrator exists,
and starts Django. It does not reset an existing administrator's password.

Leave this terminal open. Django administration will be available at:

**http://127.0.0.1:8000/admin/**

Find the generated administrator credentials in `backend/.env`:

```dotenv
INITIAL_ADMIN_USERNAME=admin
INITIAL_ADMIN_PASSWORD=<the generated value in your local file>
```

The example above explains the setting names; do not replace the generated
password with the placeholder text.

## 6. Start the frontend: terminal 2

Open a second PowerShell terminal:

```powershell
cd C:\Projects\Farm_App\frontend
flutter pub get
flutter run -d edge --web-port 8080
```

Wait for Flutter to finish compiling. Edge should open the app at:

**http://localhost:8080/**

Leave both terminals open while using the app. The frontend connects to
`http://localhost:8000/api/` by default. Port `8080` is already allowed by the
backend's default CORS configuration.

## 7. Use the app

1. Register a farmer account, or sign in using the generated administrator.
2. Create a farm and enter its total area.
3. Add fields within that area.
4. Create a planting cycle from the crop catalogue.
5. Record irrigation, fertilization, treatments, observations or harvests.
6. Open the journal to view totals and recent activity.

For weather, add the farm's latitude and longitude, then open **Weather → Weather
settings**, enable **Connected**, and select the public Open-Meteo service.
Public mode works without an API key. Customer mode accepts a customer key.
Unavailable readings display `--`.

## 8. Run the app on another day

Ensure PostgreSQL is running. You do not need to repeat installation or database
initialization.

**Terminal 1 — backend:**

```powershell
cd C:\Projects\Farm_App
.\.venv\Scripts\python.exe scripts\run_backend.py 127.0.0.1:8000
```

**Terminal 2 — frontend:**

```powershell
cd C:\Projects\Farm_App\frontend
flutter run -d edge --web-port 8080
```

Press **Ctrl+C** in each terminal to stop its server.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| `python`, `git` or `flutter` is not recognized | Check that the tool is installed and its executable directory is on Path. Reopen PowerShell after changing Path. |
| Python opens the Microsoft Store | Install Python and check Windows App execution aliases if a Store alias is taking precedence over the installed interpreter. |
| PostgreSQL connection refused | Open Windows Services and start the PostgreSQL service. Check `DB_HOST` and `DB_PORT` in `.env`. |
| PostgreSQL password authentication failed | Correct `DB_USER` and `DB_PASSWORD` in `.env`, using the credentials from PostgreSQL installation. |
| Permission denied when creating the database | The initializer needs a PostgreSQL account allowed to create databases. The locally installed `postgres` account normally has this permission. |
| A backend package cannot be imported | Repeat the requirements installation using `.\.venv\Scripts\python.exe`, then start Django using that same interpreter. |
| Port 8000 or 8080 is already in use | An earlier server may still be running. Use it or stop it in its original terminal before starting another instance. |
| Edge is missing from `flutter devices` | Ensure Edge is installed. Run `flutter config --enable-web` and check `flutter devices` again. |
| The frontend cannot reach Django | Keep the backend running on port 8000 and use the frontend on port 8080. Check the backend terminal for errors. |
| Login fails with administrator credentials | Use the values from this computer's `.env`. Initial setup preserves existing administrators; editing the initial-password setting does not reset an existing account. |
| Weather shows `--` | Check the farm coordinates and Connected setting. Public mode needs internet access; customer mode also needs a valid key. |

## Optional verification

From the project root, with PostgreSQL running:

```powershell
.\.venv\Scripts\python.exe scripts\test_backend.py
.\.venv\Scripts\python.exe backend\manage.py makemigrations --check --dry-run
```

The tests create a separate test database, so the PostgreSQL user must have
permission to create databases. The migrations check should report no changes.

From `frontend/`:

```powershell
flutter analyze
flutter test
```

For the separate live Flutter/Django/PostgreSQL test runner and native
Windows/Android configuration, see [README.md](README.md). Native Windows needs
Developer Mode and the Visual Studio C++ toolchain; Android needs the Android SDK
and a connected device or emulator. See [PROGRESS.md](PROGRESS.md) for the
platforms actually verified and the remaining limitations.
