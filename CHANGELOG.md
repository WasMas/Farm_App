# Changelog

## 0.1.0 — 2026-10-18 (local first-month MVP)

- Established the Fieldbook repository and first-month MVP scope.
- Set up Django 6.1.2, DRF, PostgreSQL, a custom user foundation, and local configuration.
- Added Flutter platforms, the paper/olive theme, and a verified live API connection.
- Added registration, JWT authentication, role groups, secure session storage, and initial admin bootstrap.
- Added an isolated PostgreSQL/Flutter integration runner; authentication checks passed.
- Completed farms, fields, membership permissions, area validation, and Flutter CRUD screens with passing integration and responsive widget tests.
- Completed the crop catalogue and planting lifecycle, with stage tracking, historical seasons, and protected relationships.
- Added cultivation/observation/harvest history, validation, search, and immutable admin audit entries.
- Added Open-Meteo weather, optional encrypted customer keys, unavailable-value placeholders, and a verified live provider fetch.
- Added a dashboard based on saved farm records, with unit-aware totals and automatic refresh after changes.
- Completed the responsive paper/olive theme with bundled Lora/DM Sans, a custom field illustration, and persistent dark/device appearance.
- Added corrected MVP class/use-case UML sources, architecture notes and full run instructions.
- Fixed expert-role write restrictions, malformed ID filters, transient token-refresh failures, expired-token logout, and compact-screen layout regressions.
- Verified 19 Django tests, 20 Flutter tests with rendered previews, all 7 live PostgreSQL integrations, and Android debug/web builds.
- Native Windows packaging remains blocked by local symlink/toolchain prerequisites; physical-device and Apple/Linux native testing remain pending.
