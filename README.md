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
