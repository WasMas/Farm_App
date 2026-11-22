# Farm_App validation matrix

Baseline commit `522bcb4`, branch `test_project`, 22 November 2026. Section numbers follow the course brief. Test names in the tables are searchable in the [backend execution report](evidence/backend.txt). The [Flutter report](evidence/activity-widget.txt) records the activity-history widget run.

## Functional scope (§4)

| Requirement | Test and tool | Evidence and outstanding checks |
|---|---|---|
| Authentication and three access profiles | Django REST Framework (DRF), `test_registration_cannot_choose_admin_and_tokens_logout`, `test_admin_can_change_user_role`, `test_worker_cannot_create_farms_but_can_read_assigned_farm` | Backend report. The implemented account roles are administrator, owner and worker. |
| Four related entities with CRUD | DRF, `test_isolation_and_relation_validation`, `test_cycle_lifecycle_and_area`, `test_units_dates_and_observations` | Partial. Farm → field → crop cycle → activity is exercised. Record create, read, update and permitted delete for each, plus the membership relationship. |
| Status workflow | DRF, `test_cycle_lifecycle_and_area`, `test_accepting_future_recommendation_is_rejected` | Backend report covers cycle completion, release of occupied area and a rejected recommendation transition. |
| Aggregated dashboard with filters | DRF, `test_summary_converts_units_and_isolates_users` | Covers totals, time windows and user isolation. Add a user-selected dashboard filter check. |
| Search or filtering on high-volume records | Flutter, “Activity history renders and searches” | Widget report, two viewport widths with fixture data. Live repository-level scenario in `frontend/test/live_activities_test.dart` also targets history filters. |
| Sensitive-action audit | DRF, `test_units_dates_and_observations`, `test_admin_owner_creation_creates_audit_event`, `test_admin_audit_filters_by_action_actor_and_entity` | Backend report. For the demo show actor, action, affected record and timestamp together. |

### Testable business rules

| Rule | Django/DRF test in backend report |
|---|---|
| Public registration cannot grant administrator access | `test_registration_cannot_choose_admin_and_tokens_logout` |
| Active plantings cannot exceed field area | `test_cycle_lifecycle_and_area` |
| A planting date cannot be in the future | `test_crop_reference_is_admin_only_and_invalid_dates` |
| An irrigation entry cannot use a mass unit | `test_units_dates_and_observations` |
| An activity cannot predate planting | `test_units_dates_and_observations` |
| A cycle with activity history cannot be deleted | `test_units_dates_and_observations` |

## Quality characteristics (§6) and test layers (§7)

“Open” means this baseline has no execution evidence for that check. Targets below are proposed project criteria where the brief leaves a choice.

| Characteristic | Requirement and test layer | Tool or scenario | Evidence or remaining work |
|---|---|---|---|
| Functional suitability | Validate isolated business logic, API contracts, API/database integration and a complete UI journey | Django/DRF tests above. Proposed isolated unit test for quantity conversion and browser journey to record and find an activity | Backend report covers API and integration. Isolated rule test and full browser E2E evidence open. |
| Performance | Dashboard p95 below 500 ms with 20 concurrent authenticated users | Proposed Locust workload on seeded farms | Open. Record dataset size, duration, throughput, latency and errors. |
| Compatibility | Same activity workflow succeeds in two browsers | Chromium and Firefox with the same seeded records | Open. Capture browser versions and outcomes. |
| Usability | A farmer can find an activity on narrow and wide screens and complete the journey using a keyboard | Flutter activity history widget plus keyboard acceptance scenario | Two widget cases passed. Keyboard navigation, focus visibility and user acceptance open. |
| Reliability | Repeating an operation preserves state. A failed write preserves existing data | Django `test_bootstrap_is_idempotent_and_does_not_reset_password`; proposed failed-write and retry with database postconditions | Backend report covers repeated bootstrap. Transaction recovery open. |
| Security | Verify authentication, authorization and known weakness checks | Django access tests above; proposed Bandit (SAST), pip-audit (SCA) and passive HTTP header review with ZAP (DAST) | Access tests in backend report. Record real scan reports, scope and triage for all three analysis layers. |
| Maintainability | Measure coverage and identify complex code | Proposed coverage.py branch report and Radon complexity report; review hotspots against the architecture | Open. Record metrics for the tested revision. |
| Portability | A second environment can install, migrate, start and pass a health check using the documented procedure | [Setup guide](../../SETUP.md), `test_postgresql_health`, clean-environment smoke test | Backend report covers local database health. Independent installation evidence open. |

## Evidence reproduction

From the repository root with the documented local dependencies and PostgreSQL available:

```powershell
.\.venv\Scripts\python.exe scripts/test_backend.py --verbosity 2
Push-Location frontend
flutter test --no-pub --reporter expanded test/activities_widget_test.dart
Pop-Location
```

## Submission and live validation (§8)

| Deliverable | Repository evidence / remaining action |
|---|---|
| Versioned source | Git history at the baseline commit above. |
| Design report | [Architecture](../architecture.md), [class diagram](../class-diagram.puml), [use cases](../use-cases.puml). Align role names with the implementation and verify the stack rationale. |
| Traceability and executable suites | This matrix and the linked reports. Close each open layer with a named scenario, command and result. |
| ISO conformity report | Use the eight rows above as its index. Attach measured results and disclose outstanding failures. |
| Installation guide | Validate the linked setup guide on a second environment. |
| Ten-minute presentation, 26 November | Demonstrate one activity, inspect its audit record, run the DRF activity tests live and run the Flutter history tests live. Rehearse the timing. |

Baseline execution totals: 37 Django tests passed in 14.787 seconds. Both Flutter activity-history tests passed.
