# Fieldbook · commandes de soutenance

PowerShell · PostgreSQL démarré · [Diapos](Fieldbook-Soutenance.pptx) · [Preuves ISO 25010](traceability.md)

## 1 · Préparer la démo

```powershell
cd D:\Farm_App
git switch test_project   # Ouvre la branche de soutenance.
.\.venv\Scripts\python.exe scripts/demo.py --check   # Vérifie les données de démo.
.\.venv\Scripts\python.exe -m playwright install chromium firefox   # Installe les navigateurs.
cd frontend
flutter pub get --enforce-lockfile   # Installe les dépendances Flutter.
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/   # Compile l’interface.
```

## 2 · Démarrer l’application

**Terminal 1 · Django**

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe scripts/demo.py   # Démarre l’API et affiche le mot de passe de demo_admin.
```

**Terminal 2 · Flutter**

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe -m http.server 8080 --bind 127.0.0.1 --directory frontend/build/web   # Sert l’interface.
```

[Ouvrir Flutter](http://localhost:8080) (`demo_owner` / `FieldbookDemo123!`) · [Voir l’audit](http://127.0.0.1:8000/admin/core/auditevent/) (`demo_admin`). **Ctrl+C** pour arrêter.

## 3 · Diapo 4 · Deux tests en direct

```powershell
cd D:\Farm_App
# Simule une panne d’audit puis réessaie. Une seule activité doit être enregistrée.
.\.venv\Scripts\python.exe scripts/test_backend.py activities.tests.ActivityTests.test_failed_audit_rolls_back_activity_and_retry_succeeds -v 2
cd frontend
flutter test --no-pub --reporter expanded test/activities_widget_test.dart   # Teste la recherche à 390 et 1 440 px.
```

## 4 · Voir Chromium et Firefox

```powershell
cd D:\Farm_App
$env:PWDEBUG = '1'   # Ouvre Playwright Inspector.
try {
    # Connecte l’admin au clavier et vérifie l’audit dans les deux navigateurs.
    .\.venv\Scripts\python.exe scripts/test_backend.py core.quality_live.LiveQualityTests.test_admin_audit_keyboard_journey -v 2
} finally {
    Remove-Item Env:PWDEBUG
}
```

**Step over** = avancer d’une action. **Resume** = terminer le test.

## 5 · Diapo 6 · ZAP

```powershell
cd D:\Farm_App
# Affiche les alertes enregistrées pour la soutenance.
(Get-Content docs/Test/evidence/zap-passive.json -Raw | ConvertFrom-Json).findings | Format-Table risk,rule,path,alert -Wrap
```

```powershell
$jar = Join-Path $env:TEMP 'farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar'
java -jar $jar -host 127.0.0.1 -port 8092   # Ouvre ZAP Desktop.
```

Avec l’appli démarrée : **Safe Mode → Manual Explore → http://localhost:8080 → Launch Browser**. Se connecter, ouvrir le journal, puis **Alerts** dans ZAP.

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe scripts/demo.py --passive-zap "$env:TEMP\farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar"   # Rejoue le parcours avec ZAP (ports 8091 et 18000 libres).
(Get-Content test-results/zap-passive.json -Raw | ConvertFrom-Json).findings | Format-Table risk,rule,path,alert -Wrap   # Affiche les nouvelles alertes.
```

## 6 · Autres tests

```powershell
cd D:\Farm_App
$py = (Resolve-Path .\.venv\Scripts\python.exe).Path   # Python du projet pour les commandes suivantes.
```

> [!example]- Unitaires, intégration et fiabilité
> ```powershell
> & $py scripts/test_backend.py core --tag unit -v 2   # Vérifie les identifiants positifs.
> & $py -m unittest discover -s scripts -p test_demo_web_build.py -v   # Vérifie le choix du build Flutter.
> & $py scripts/test_backend.py core.tests.JournalCrudTests -v 2   # Crée, lit, modifie et supprime les quatre entités.
> & $py scripts/test_backend.py crops.tests -k remaining_hectare -v 2   # Teste la limite à 0,99 / 1,00 / 1,01 ha.
> & $py scripts/test_backend.py crops.test_concurrency -v 2   # Deux demandes pour le dernier hectare, une seule acceptée.
> Push-Location frontend
> flutter test --no-pub test/activity_unit_test.dart test/session_error_test.dart   # Teste les quantités et la reprise de session.
> Pop-Location
> ```
> [Rapport de concurrence · diapo 5](evidence/planting-race.txt)

> [!example]- Performance
> ```powershell
> $env:DB_POOL = '1'
> try {
>     & $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_dashboard_load -v 2   # Mesure le p95 sur 100 lectures (20 utilisateurs).
> } finally {
>     Remove-Item Env:DB_POOL
> }
> ```
> [Résultat GitHub · p95 de 448,9 ms](https://github.com/WasMas/Farm_App/actions/runs/45043679144/job/137275114823)

> [!example]- Sécurité et couverture
> ```powershell
> & $py -m bandit -r backend -x tests.py,quality_live.py,migrations,seed_demo.py -ll   # Cherche les problèmes de sécurité Python.
> docker run --rm -v "${PWD}:/src" -w /src semgrep/semgrep:1.125.0 semgrep scan --config .github/dart-security.yml --metrics=off --error frontend/lib   # Vérifie la règle TLS Dart.
> & $py -m pip_audit --local   # Vérifie les dépendances Python.
> & $py scripts/audit_pub.py   # Vérifie les dépendances Dart.
> & $py -m radon cc backend -s -n C   # Liste les fonctions complexes.
> & $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_unauthenticated_http_response -v 2   # Vérifie le refus HTTP 401 et les en-têtes.
> $data = Join-Path $env:TEMP 'farm-present-covdata'
> & $py -m coverage run --data-file="$data" backend/manage.py test core activities crops -v 1   # Mesure la couverture Python.
> & $py -m coverage report --data-file="$data"   # Affiche le pourcentage couvert.
> Push-Location frontend
> flutter test --no-pub --coverage test/activities_widget_test.dart   # Mesure la couverture du test Flutter.
> Pop-Location
> ```
> [Rapports GitHub](https://github.com/WasMas/Farm_App/actions/runs/45043679144) · [Constats Sonar](https://sonarcloud.io/project/issues?id=WasMas_Farm_App&branch=test_project&resolved=false)
