---
tags: [soutenance, commandes]
---

# Fieldbook · commandes de soutenance

PowerShell sur le PC de démo, avec PostgreSQL démarré. Pour le passage de 10 minutes, suivre **1 à 3**. La section **4** permet de montrer les navigateurs à la demande. Le texte à dire est dans les notes du [PowerPoint](Fieldbook-Soutenance.pptx). La [matrice ISO/IEC 25010](traceability.md) relie chaque critère aux tests et aux résultats enregistrés. Pour la diapo 5, ouvrir le [rapport des deux demandes concurrentes](evidence/planting-race.txt).

## 1 · Préparer avant le passage

```powershell
cd D:\Farm_App                              # Ouvre le projet.
git switch test_project                     # Sélectionne la branche de soutenance.
.\.venv\Scripts\python.exe scripts/demo.py --check   # Vérifie la base et les données de démo.
.\.venv\Scripts\python.exe -m playwright install chromium firefox   # Installe les deux navigateurs de test.
cd frontend                                 # Ouvre le projet Flutter.
flutter pub get --enforce-lockfile           # Récupère les versions prévues des dépendances.
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/   # Compile l’interface pour l’API locale.
```

## 2 · Démarrer l’application

**Terminal 1 — Django.** Crée une ferme de démo et démarre l’API. Garder ce terminal ouvert.

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe scripts/demo.py
```

**Terminal 2 — Flutter.** Sert l’interface compilée. Garder ce terminal ouvert.

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe -m http.server 8080 --bind 127.0.0.1 --directory frontend/build/web
```

Ouvrir [Flutter](http://localhost:8080) avec `demo_owner` / `FieldbookDemo123!`. Enregistrer une observation « TEK-UP feuilles saines », puis la rechercher. Ouvrir le [journal d’audit](http://127.0.0.1:8000/admin/core/auditevent/) avec `demo_admin` et le mot de passe du terminal 1. À la fin, **Ctrl+C** dans les terminaux 2 et 1.

## 3 · Diapo 4 (B4) · Deux tests en direct

**Terminal 3 — API.** Simule une panne d’audit, puis réessaie. Résultat attendu : une seule activité avec sa trace et `OK`.

```powershell
cd D:\Farm_App
.\.venv\Scripts\python.exe scripts/test_backend.py activities.tests.ActivityTests.test_failed_audit_rolls_back_activity_and_retry_succeeds -v 2
```

**Même terminal — Flutter.** Vérifie la recherche du journal à 390 et 1 440 px. Résultat attendu : `All tests passed!`.

```powershell
cd D:\Farm_App\frontend
flutter test --no-pub --reporter expanded test/activities_widget_test.dart
```

## 4 · Voir Chromium et Firefox avec Playwright

Ce test démarre son propre serveur Django temporaire. Il fonctionne même si les terminaux 1 et 2 sont fermés.

```powershell
cd D:\Farm_App
$env:PWDEBUG = '1'   # Affiche le navigateur et ouvre Playwright Inspector.
try {
    # Teste la connexion admin au clavier et la ligne d’audit dans Chromium, puis Firefox.
    .\.venv\Scripts\python.exe scripts/test_backend.py core.quality_live.LiveQualityTests.test_admin_audit_keyboard_journey -v 2
} finally {
    Remove-Item Env:PWDEBUG   # Désactive le mode visible après le test.
}
```

Dans **Inspector**, cliquer sur **Step over** pour avancer, ou **Resume ▶** pour continuer. Chercher `keyboard login and audit row verified` pour chaque navigateur, puis `OK`.

## 5 · Diapo 6 · Montrer les alertes ZAP

**Ouvrir l’interface OWASP ZAP.** Démarrer Django et Flutter (section 2), puis lancer dans un troisième terminal :

```powershell
java -jar "$env:TEMP\farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar" -host 127.0.0.1 -port 8092   # Ouvre ZAP Desktop ; le port 8080 reste disponible pour Flutter.
```

1. Dans ZAP, choisir **Safe Mode**, puis **Quick Start → Manual Explore**.
2. Saisir `http://localhost:8080`, choisir **Edge** et cliquer sur **Launch Browser**. Dans ce navigateur, se connecter à Fieldbook et ouvrir le journal.
3. Revenir dans ZAP. En bas, ouvrir **Alerts**, déplier une alerte et sélectionner une URL de l’API (`127.0.0.1:8000`). Montrer le niveau de risque et le champ **Evidence**. [Guide de l’interface ZAP](https://www.zaproxy.org/docs/desktop/ui/)

**Pendant la soutenance** — afficher le rapport déjà enregistré :

```powershell
cd D:\Farm_App
$zap = Get-Content docs/Test/evidence/zap-passive.json -Raw | ConvertFrom-Json   # Ouvre le rapport fourni avec la présentation.
$zap.findings | Format-Table risk,rule,path,alert -Wrap   # Affiche les alertes par route.
```

Montrer la règle **10036** : quatre réponses de l’API révèlent la version du serveur dans l’en-tête `Server`. Le rapport contient aussi deux alertes informatives. [Résultat du job ZAP sur GitHub](https://github.com/WasMas/Farm_App/actions/runs/45043679144/job/137275114891).

**Pour obtenir un nouveau rapport**, lancer le scan passif depuis la racine du projet.

```powershell
cd D:\Farm_App
$jar = Join-Path $env:TEMP 'farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar'   # Localise ZAP sur ce PC.
.\.venv\Scripts\python.exe scripts/demo.py --passive-zap $jar   # Observe la connexion, le tableau de bord et la recherche dans Flutter.
$zap = Get-Content test-results/zap-passive.json -Raw | ConvertFrom-Json   # Lit le résultat de cette exécution.
$zap.findings | Format-Table risk,rule,path,alert -Wrap
```

Le script démarre sa propre démo. PostgreSQL doit tourner et les ports **8091** et **18000** doivent être libres.

## 6 · Autres commandes si le jury demande

Depuis un terminal PowerShell, initialiser ces deux lignes une fois :

```powershell
cd D:\Farm_App                      # Toutes les commandes ci-dessous partent de la racine.
$py = (Resolve-Path .\.venv\Scripts\python.exe).Path   # Utilise le Python du projet.
```

> [!example]- Tests unitaires, intégration et fiabilité
> ```powershell
> & $py scripts/test_backend.py core --tag unit -v 2   # Vérifie les identifiants positifs.
> & $py -m unittest discover -s scripts -p test_demo_web_build.py -v   # Teste les quatre cas du build de démo.
> & $py scripts/test_backend.py core.tests.JournalCrudTests -v 2   # Crée, lit, modifie et supprime les quatre entités.
> & $py scripts/test_backend.py crops.tests -k remaining_hectare -v 2   # Vérifie 0,99 / 1,00 / 1,01 ha.
> & $py scripts/test_backend.py crops.test_concurrency -v 2   # Deux demandes concurrentes : un 201, un 400.
> Push-Location frontend   # Passe dans le projet Flutter.
> flutter test --no-pub test/activity_unit_test.dart test/session_error_test.dart   # Vérifie les quantités et la session après une panne.
> Pop-Location   # Revient à la racine.
> ```

> [!example]- Charge du tableau de bord
> ```powershell
> $env:DB_POOL = '1'   # Active le pool de connexions PostgreSQL pour la mesure.
> try {
>     & $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_dashboard_load -v 2   # 20 utilisateurs × 5 lectures.
> } finally {
>     Remove-Item Env:DB_POOL   # Rétablit le comportement habituel.
> }
> ```
> Lire la ligne `Dashboard:`. [Résultat GitHub : p95 de 448,9 ms pour une cible de 500 ms](https://github.com/WasMas/Farm_App/actions/runs/45043679144/job/137275114823).

> [!example]- Sécurité, couverture et qualité
> ```powershell
> & $py -m bandit -r backend -x tests.py,quality_live.py,migrations,seed_demo.py -ll   # Cherche les alertes Python moyennes ou élevées.
> docker run --rm -v "${PWD}:/src" -w /src semgrep/semgrep:1.125.0 semgrep scan --config .github/dart-security.yml --metrics=off --error frontend/lib   # Vérifie la règle TLS Dart avec Docker.
> & $py -m pip_audit --local   # Recherche des avis de sécurité sur les dépendances Python.
> & $py scripts/audit_pub.py   # Vérifie les paquets Dart auprès d’OSV (nécessite PyYAML).
> & $py -m radon cc backend -s -n C   # Liste les fonctions Python de complexité C ou plus.
> & $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_unauthenticated_http_response -v 2   # Vérifie le refus HTTP 401 et les en-têtes.
> ```
> Pour mesurer aussi la couverture sur le PC :
> ```powershell
> $data = Join-Path $env:TEMP 'farm-present-covdata'   # Garde la mesure hors du dépôt.
> & $py -m coverage run --data-file="$data" backend/manage.py test core activities crops -v 1   # Mesure ces trois modules Django.
> & $py -m coverage report --data-file="$data"   # Affiche le résultat de cette exécution.
> Push-Location frontend   # Passe dans le projet Flutter.
> flutter test --no-pub --coverage test/activities_widget_test.dart   # Écrit coverage/lcov.info pour ce test.
> Pop-Location   # Revient à la racine.
> ```
> Les rapports de la suite complète Python et Flutter sont dans **Summary → Artifacts → coverage** du [run de référence](https://github.com/WasMas/Farm_App/actions/runs/45043679144). Pour les constats de la diapo 7, ouvrir [Sonar → Issues](https://sonarcloud.io/project/issues?id=WasMas_Farm_App&branch=test_project&resolved=false).
