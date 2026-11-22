# Farm_App validation matrix

Validation on Windows, branch `test_project`, 22 November 2026. Section numbers follow the course brief. Test names in the tables are searchable in the [backend execution report](evidence/validation.txt). The [Flutter report](evidence/activity-widget.txt) records the activity-history widget run.

## Functional scope (§4)

| Requirement | Test and tool | Evidence and outstanding checks |
|---|---|---|
| Authentication and three access profiles | Django REST Framework (DRF), `test_registration_cannot_choose_admin_and_tokens_logout`, `test_admin_can_change_user_role`, `test_worker_cannot_create_farms_but_can_read_assigned_farm` | Backend report. The implemented account roles are administrator, owner and worker. |
| Four related entities with CRUD | DRF, `test_isolation_and_relation_validation`, `test_cycle_lifecycle_and_area`, `test_units_dates_and_observations` | The integration test `test_four_entity_crud` creates, reads, edits and deletes each record through its API. Child records are deleted first. FarmMembership links users and farms through a role. |
| Status workflow | DRF, `test_cycle_lifecycle_and_area`, `test_accepting_future_recommendation_is_rejected` | Backend report covers cycle completion, release of occupied area and a rejected recommendation transition. |
| Aggregated dashboard with filters | DRF, `test_summary_converts_units_and_isolates_users` | Covers totals, time windows and user isolation. The Flutter farm selector scopes the request. `test_selected_farm_limits_dashboard` verifies the filtered count and area. |
| Search or filtering on high-volume records | Flutter, “Activity history renders and searches” | Widget report, two viewport widths with fixture data. The backend exposes date and farm filters plus text search. |
| Sensitive-action audit | DRF, `test_units_dates_and_observations`, `test_admin_owner_creation_creates_audit_event`, `test_admin_audit_filters_by_action_actor_and_entity` | Backend report. `test_failed_audit_rolls_back_activity_and_retry_succeeds` verifies actor, action, record ID and timestamp. |

### Testable business rules

| Rule | Django/DRF test in backend report |
|---|---|
| Public registration cannot grant administrator access | `test_registration_cannot_choose_admin_and_tokens_logout` |
| Active plantings cannot exceed field area | `test_cycle_lifecycle_and_area` |
| A planting date cannot be in the future | `test_crop_reference_is_admin_only_and_invalid_dates` |
| An irrigation entry cannot use a mass unit | `test_units_dates_and_observations` |
| An activity cannot predate planting | `test_units_dates_and_observations` |
| A cycle with activity history cannot be deleted | `test_units_dates_and_observations` |

## ISO/IEC 25010 conformity and test evidence (§§6–8)

| Characteristic | Acceptance check and tool | Obtained result |
|---|---|---|
| Functional suitability | Django isolated ID validation, API contract and PostgreSQL integration tests; four-entity CRUD and role enforcement. Playwright checks the admin audit journey through the UI. | [41 Django tests passed](evidence/validation.txt). [Browser journey passed](evidence/live.txt). |
| Performance efficiency | 20 authenticated clients each read the dashboard five times with one farm per account. Every response must contain exactly one farm. Target p95 <500 ms. | [100 successful requests, 84.4 requests/s, p95 341.1 ms](evidence/live.txt). The [initial run](evidence/load-before-pooling.txt) measured 3781.3 ms. Final run used IPv4 loopback, a PostgreSQL connection pool, grouped dashboard aggregates and a server queue of 64. The small fixture contains no activities. Production-scale latency remains unmeasured. |
| Compatibility | Repeat administrator sign-in and audit lookup in Chromium and Firefox with Playwright. | [Both browser engines passed](evidence/live.txt). Scope is the Django admin journey. |
| Usability | Named form fields and keyboard-only submission of the admin login. Responsive dashboard, journal search, shell navigation and sign-out at phone and desktop widths. | [Keyboard journey passed](evidence/live.txt); [17 Flutter tests passed](evidence/widgets.txt). Human acceptance can be demonstrated using the demo guide. |
| Reliability | Force the audit write to fail, verify the activity was rolled back, retry and verify exactly one activity with its timestamped audit entry. | [Django recovery test passed](evidence/validation.txt), including the database postconditions. |
| Security | DRF tests for role enforcement and tenant isolation. Passive dynamic check of a running protected HTTP route. Bandit scans Python application code. pip-audit checks installed Python dependencies against published advisories. | [HTTP 401 and both security headers verified](evidence/live.txt). [Bandit](evidence/bandit.txt) reports one medium finding: the weather service uses urlopen. Review found two hard-coded HTTPS hosts and URL-encoded query parameters. [Python dependency report](evidence/dependencies.txt). Coverage of these controls is narrower than a complete OWASP assessment. |
| Maintainability | coverage.py measures Python statements and branches during the Django suite, excluding tests and migrations. Radon identifies functions ranked C or above. | [Combined coverage 74%](evidence/coverage.txt). [Five complexity hotspots](evidence/complexity.txt), highest score 20 in crop validation. These functions are priorities for additional rule tests. |
| Portability | Bootstrap an empty PostgreSQL database, apply migrations, create a demo owner and verify fixtures. Compile a web release. The CI job repeats installation and HTTP health on a clean Ubuntu runner. | [Local clean database check](evidence/demo-setup.txt) and [Flutter web build](evidence/web-build.txt). The [Ubuntu installation and health check](https://github.com/WasMas/Farm_App/actions/runs/45026868704) passed. Its backend-quality/health.json contains the PostgreSQL response. |

The design report comprises the [architecture and stack rationale](../architecture.md), [class diagram](../class-diagram.puml) and [use cases](../use-cases.puml). The [installation guide](../../SETUP.md) and [presentation guide](DEMO.md) cover setup, reproduction and the live validation. The [workflow](../../.github/workflows/quality.yml) stores fresh reports for each run.

**Concurrent field allocation (reliability).** Two authorized clients request the same remaining hectare. Django API clients use separate PostgreSQL sessions. The test observes the database lock wait, verifies one HTTP 201 and one capacity-related HTTP 400, and checks the single persisted planting. [Test](../../backend/crops/test_concurrency.py) · [Execution report](evidence/planting-race.txt).
