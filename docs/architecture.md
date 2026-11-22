# Fieldbook architecture

## Backend

One Django project, with business-feature apps: `accounts`, `farms`, `crops`,
`activities`, `weather`, and `dashboard`. `core` holds shared API behavior and
the read-only audit log. PostgreSQL is used in development and tests.

Models describe persistence and relationships; serializers map/validate API
input; class-based views and DRF ViewSets handle requests. Weather fetching and
dashboard calculations live in service modules. Django templates power the
built-in administration site; Flutter consumes JSON rather than Django HTML.

Django provides ORM transactions, authentication and a built-in audit review interface.
PostgreSQL enforces foreign keys and supports concurrent journal updates. Flutter
provides one responsive client for field work and desktop review.

The account roles are administrator, farm owner and farm worker. Administrators
provision owners. Owners manage their farms and assign workers to fields.
Farm membership adds manager, worker and viewer permissions. The API checks
both account privileges and resource scope before allowing writes.

Each farm starts with zero or more fields. Crop types are reference data;
planting cycles identify one crop in one field over one season. Multiple active
plantings share the field's available area. Activities belong to a cycle;
irrigation is an actual event, and the latest event can be queried from history.
Harvest is an activity with an explicit unit. Referenced fields/cycles/crop types
cannot be deleted through the API; closing a season preserves its history.

JWT access tokens expire after 15 minutes; refresh tokens rotate and are
blacklisted on logout. Secure client storage holds tokens; ordinary preferences
only store appearance. Refresh-token logout does not revoke an already issued
access token before its short expiry.

`ensure_admin` uses environment credentials, password validation, a transaction,
and a PostgreSQL advisory lock. Startup runs it after migrations. It does not
replace an existing active administrator or silently promote an existing user.

## Frontend

`lib/features/<feature>/domain`, `data`, and `presentation` keep typed models,
repositories, and widgets/providers together. Reusable forms, navigation,
networking, and visual styles are in `lib/core`.

Riverpod handles asynchronous state and session changes. `go_router` protects
pages and redirects signed-out users. Dio attaches JWTs and refreshes an expired
access token once. Successful data mutations invalidate the dashboard summary.
Account-scoped providers reject anonymous reads and reload when users change.

Material 3 uses bundled OFL-licensed Lora and DM Sans fonts. The palette is olive,
paper, soil, and wheat. Field illustrations are drawn with Flutter CustomPainter.
Wide layouts use a sidebar; compact layouts use bottom navigation. Appearance
can follow the device, use warm daylight, or use the dark palette.

## Weather

Weather starts disconnected. Connect the public Open-Meteo API without a key, or
select the customer API and enter a key. Settings are personal to the account;
farms require both latitude and longitude. Customer keys are write-only through
the API and encrypted at rest with a key derived from `DJANGO_SECRET_KEY`.
Keep that secret stable: rotating it requires entering weather keys again.

The backend calls fixed Open-Meteo HTTPS endpoints, times out after 7 seconds,
and caches successful snapshots for 10 minutes. Manual refresh fetches again.
Disabled/missing configuration, fetch failures, and missing individual values
produce nulls, rendered as `--`. Previous stale values are not shown as current
after a failed refresh. Zero is displayed as a real value.

Sources: [Open-Meteo API](https://open-meteo.com/en/docs),
[secure-storage platform setup](https://pub.dev/packages/flutter_secure_storage),
[Google Fonts](https://github.com/google/fonts). Font licenses are bundled.

## Scope

No disease/yield prediction, chatbot, advanced expert review, offline sync, or
automated irrigation control is included. The MVP records actual farm work.
Native platform packaging/signing is separate from shared Flutter source and
responsive widget verification; see PROGRESS.md for actual build results.
