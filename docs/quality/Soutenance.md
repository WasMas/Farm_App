---
aliases: [Démo Fieldbook]
tags: [soutenance, tests, iso25010]
---

# Fieldbook · conducteur de soutenance

**TEK-UP · 26 novembre 2026 · 10 minutes · PowerShell sur Windows.** Ouvrir le [PowerPoint](Fieldbook-Soutenance.pptx) et cette note côte à côte pour répéter. Dans Obsidian, ouvrir le dossier du dépôt comme coffre et passer cette note en mode Lecture. Les blocs de commandes se copient séparément.

> [!important] Ce qu’il faut exécuter devant le jury
> Montrer l’application en direct, puis lancer **deux tests** au terminal 3 (§ B4). Garder le graphe GitHub, Sonar et les mesures déjà ouverts. La suite complète (§ C) sert à préparer les preuves et à répondre aux questions.

### Le projet en une minute

Le propriétaire gère les fermes et affecte le travail. L’ouvrier intervient sur les parcelles qui lui sont attribuées. L’administrateur gère les accès et consulte l’audit. Les quatre objets du parcours sont la **ferme**, la **parcelle**, le **cycle de plantation** et l’**activité**. Django REST Framework expose ces objets à Flutter et PostgreSQL conserve leurs relations. Un cycle passe d’actif à terminé, ce qui libère de la surface tout en conservant son historique.

Si le jury demande cinq règles métier, citer les suivantes : l’inscription publique exclut le rôle administrateur, les plantations actives respectent la surface de la parcelle, la plantation ne peut pas être datée dans le futur, une irrigation exige une unité adaptée et une activité doit avoir lieu à partir de la date de plantation. La [matrice](traceability.md) donne le test de chaque règle. Le [rapport d’architecture](../architecture.md), le [diagramme de classes](../class-diagram.puml) et les [cas d’utilisation](../use-cases.puml) complètent la démonstration.

## A · Avant le passage

### A1 · Préparer le PC une fois

Sur ce PC, le projet, PostgreSQL, Flutter, le fichier local `backend/.env` et l’environnement Python sont déjà installés. Sur une nouvelle machine, commencer par le [guide d’installation](../../SETUP.md). Le compte PostgreSQL local doit pouvoir créer les bases temporaires. La CI utilise Python 3.14, PostgreSQL 17 et Flutter 3.50.0.

```powershell
Set-Location D:\Farm_App
git switch test_project
git status -sb
Get-Service *postgres* | Select-Object Name, Status
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt -r scripts/quality-requirements.txt
.\.venv\Scripts\python.exe -m playwright install chromium firefox
.\.venv\Scripts\python.exe scripts/demo.py --check
Set-Location frontend
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

Attendre `Demo owner login, farms and activity fixtures verified.` et la fin de la compilation. La démo de classe utilise le port **8000**. L’artefact Flutter de la CI est compilé pour le port **18000** de ZAP.

### A2 · Préparer trois terminaux

**Terminal 1 · API et données fictives.** S’il tourne déjà avec `scripts/demo.py`, conserver ce terminal. Sinon lancer ci-dessous. Il reste ouvert et affiche un mot de passe administrateur temporaire.

```powershell
Set-Location D:\Farm_App
.\.venv\Scripts\python.exe scripts/demo.py
```

**Terminal 2 · Interface Flutter.** Si elle est déjà servie sur le port 8080, utiliser l’instance existante.

```powershell
Set-Location D:\Farm_App
.\.venv\Scripts\python.exe -m http.server 8080 --bind 127.0.0.1 --directory frontend/build/web
```

**Terminal 3 · Démo et tests.** Ouvrir les deux onglets avant de commencer le chronomètre.

```powershell
Set-Location D:\Farm_App
Invoke-RestMethod http://127.0.0.1:8000/api/health/
Start-Process 'http://localhost:8080'
Start-Process 'http://127.0.0.1:8000/admin/core/auditevent/'
```

Connexion Flutter avec `demo_owner` et le mot de passe du jeu de démo `FieldbookDemo123!`. Dans l’admin Django, utiliser `demo_admin` et le mot de passe imprimé dans le terminal 1. Garder les deux onglets connectés. Ne projeter ni mot de passe ni jeton.

### A3 · Ouvrir les preuves avant d’entrer

- [ ] Ouvrir le [run de référence, 13 jobs réussis au commit 820fa5b](https://github.com/WasMas/Farm_App/actions/runs/45043679144), agrandir son graphe et repérer les artefacts sous **Summary**.
- [ ] Ouvrir la [liste Issues de Farm_App](https://sonarcloud.io/project/issues?id=WasMas_Farm_App&branch=test_project&resolved=false). Sélectionner **test_project → All issues**. La capture intégrée conserve les deux premiers constats du 22 novembre.
- [ ] Garder le PowerPoint, la [matrice des huit caractéristiques](traceability.md), le [rapport ZAP](evidence/zap-passive.json) et les [mesures locales](evidence/live.txt) disponibles hors ligne. Agrandir le texte du terminal.

## B · Les dix minutes, dans l’ordre des diapositives

### B1 · 0:00–0:25 · Le métier

Diapo 1. « Fieldbook permet à un propriétaire et à ses ouvriers de suivre les travaux de la ferme. Nous allons enregistrer une observation, puis vérifier qui l’a créée et ce qui se passe si son audit échoue. » Montrer le tableau de bord connecté.

### B2 · 0:25–1:55 · Enregistrer, retrouver, auditer

Diapo 2, puis basculer sur Flutter. Sélectionner la ferme, cliquer sur **Record today’s work**, choisir **Observation**, une plantation active et la date du jour. Saisir **TEK-UP feuilles saines**, puis enregistrer. Aller à **All records** et rechercher **TEK-UP**. Dans l’onglet Django, actualiser. Lire sur la même ligne l’acteur, `create`, `activities.Activity`, l’identifiant et l’heure. L’audit concerne la modification métier. Les logs techniques du serveur servent au diagnostic. Si l’interface est indisponible, les captures de la diapo 2 illustrent les deux écrans.

### B3 · 1:55–2:40 · Deux unitaires et un parcours API

Diapo 3. Python accepte l’identifiant positif `42` et rejette `0`, `-2`, du texte et la valeur absente. Dart affiche la quantité `12.500` avec son unité sous la forme `12.5 m³`. Les deux tests passent. Le test d’intégration crée quatre objets liés, vérifie la modification de chacun, puis les supprime. Il observe 201 à la création, 200 à la modification, 204 à la suppression et 404 à la relecture. Il fait partie des 41 tests réussis du job API.

### B4 · 2:40–4:20 · Deux couches de test en direct

**1. API et PostgreSQL.** Lancer au terminal 3. Pendant les migrations, expliquer que le test interrompt volontairement l’écriture de l’audit. Il vérifie zéro activité après l’échec, puis une seule activité et son audit après la nouvelle tentative.

```powershell
Set-Location D:\Farm_App
.\.venv\Scripts\python.exe scripts/test_backend.py activities.tests.ActivityTests.test_failed_audit_rolls_back_activity_and_retry_succeeds -v 2
```

Montrer le nom du test, `Ran 1 test` et `OK`. **2. Composants Flutter.** Montrer les deux largeurs et `All tests passed!`. Le widget affiche une irrigation de 12,5 m³. Avec la recherche `unmatched`, il affiche « A fresh page » aux deux largeurs.

```powershell
Set-Location D:\Farm_App\frontend
flutter test --no-pub --reporter expanded test/activities_widget_test.dart
Set-Location ..
```

### B5 · 4:20–5:00 · Deux demandes pour le dernier hectare

Diapo 5. Deux personnes autorisées demandent chacune le dernier hectare. Le verrou pessimiste protège la parcelle dans PostgreSQL. La seconde transaction attend, puis relit la surface disponible. Résultat attendu, dans un ordre variable selon l’acteur : un **201**, un **400**, une plantation de **1 ha**. Le test vérifie aussi l’attente réelle sur verrou. Réserver la commande § C3 aux questions.

### B6 · 5:00–5:50 · Ce que les trois contrôles de sécurité examinent

Diapo 6. **SAST** lit le code, **SCA** compare les versions de dépendances aux avis publiés, **DAST passif** observe le trafic réel du parcours Flutter. Dans le JSON ZAP, repérer la règle **10036**, le risque **Low**, la route et le champ de réponse `Server`. Quatre occurrences concernent quatre routes du serveur local. Les deux autres alertes sont informatives. Le TP4 fournit aussi une correction vérifiable de setuptools et son retest (§ C4).

### B7 · 5:50–6:40 · Ce que Sonar a enregistré

Diapo 7. « GitHub lance le scanner Sonar à chaque push sur notre branche. Il examine les fichiers et publie ses constats dans Issues. Sur cette capture, la liste compte 19 constats ouverts. Le premier signale le mot de passe de démonstration dans `seed_demo.py`, ligne 408. Le deuxième recommande de fixer l’action référencée dans `quality.yml`, ligne 310, à un identifiant de commit complet. » Pointer le message, le statut **Open**, le niveau et la ligne. [Ouvrir la liste des issues](https://sonarcloud.io/project/issues?id=WasMas_Farm_App&branch=test_project&resolved=false).

### B8 · 6:40–7:25 · Interpréter la charge

Diapo 8. « 20 propriétaires démarrent ensemble. Chacun envoie cinq lectures successives, donc 100 requêtes au total et au plus 20 en vol. » Pour ces 100 réponses triées, le p95 est la 95ᵉ durée. La mesure locale archivée passe de **3 781,3 ms** avant optimisation à **341,1 ms** après, pour une cible **strictement inférieure à 500 ms**. Petit jeu de 20 fermes sans activités. Sur le [runner GitHub de 820fa5b](https://github.com/WasMas/Farm_App/actions/runs/45043679144/job/137275114823), les 100 lectures ont réussi avec un p95 de **448,9 ms** et un débit de **71,2 requêtes/s**.

### B9 · 7:25–9:30 · Présenter le pipeline après les exemples

Diapo 9. « GitHub rejoue ces vérifications à chaque push sur test_project. » Afficher le [graphe des 13 jobs](https://github.com/WasMas/Farm_App/actions/runs/45043679144). Dans PowerPoint, **Affichage → Notes** ou le **Mode Présentateur** affiche le texte à dire pour chacune des cinq étapes.

1. **Installation et compilation (2 jobs).** Django démarre avec PostgreSQL et répond au contrôle de santé. Flutter produit le build web.
2. **Unitaires et composants (2 jobs).** Python vérifie les petites règles et les options de démo. Flutter teste les données et les widgets.
3. **Intégration et fiabilité (3 jobs).** L’API teste ses échanges avec PostgreSQL. La fiabilité couvre les pannes, le verrou et la session. Playwright vérifie le parcours admin dans deux navigateurs.
4. **Analyses statiques (4 jobs).** SAST lit le code, SCA contrôle les dépendances, un job fusionne la couverture. Une fois celle-ci prête, Sonar lance son analyse et publie les constats.
5. **Tests dynamiques (2 jobs).** ZAP observe le parcours Flutter. En parallèle, la charge mesure le tableau de bord. Montrer le journal d’un job ou ouvrir son rapport sous **Artifacts**.

### B10 · 9:30–10:00 · Revenir aux exigences

Diapo 10. Ouvrir la [matrice](traceability.md) sur une ligne choisie par le jury. Exemple : compatibilité → parcours admin au clavier → Playwright → Chromium et Firefox. Terminer sur les treize jobs réussis et les constats que le groupe peut examiner dans Sonar. La mesure de charge porte sur le petit jeu de démonstration. À la fin, faire **Ctrl+C** dans le terminal 2 puis le terminal 1 si vous les avez démarrés pour cette démo. Le script Django supprime sa base jetable.

## C · Répétition complète par catégorie

Les blocs suivants sont indépendants après l’initialisation ci-dessous. Les exécuter en PowerShell depuis la racine, dans le même terminal. Les vérifications en ligne (OSV, pip-audit, Sonar) demandent un accès réseau. Les tests Django utilisent une base de test distincte de la démo. Exécuter un seul groupe Django local à la fois.

```powershell
Set-Location D:\Farm_App
$root = (Get-Location).Path
$py = (Resolve-Path .\.venv\Scripts\python.exe).Path
$apps = 'accounts','activities','ai_chat','core','crops','dashboard','farms','predictions','recommendations','weather'
$out = Join-Path $root '.local\soutenance-rapports'
New-Item -ItemType Directory -Force $out | Out-Null
```

### C1 · Installation et portabilité

```powershell
& $py scripts/demo.py --check
Push-Location frontend
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
Pop-Location
```

Montrer les migrations sur base neuve et le build web. La preuve sur une seconde plateforme se trouve dans **Installation Django et PostgreSQL → Migrations et santé HTTP**, artefact **installation/health.json** sur Ubuntu.

### C2 · Unitaires Python et Dart, puis composants Flutter

```powershell
& $py scripts/test_backend.py @apps --tag unit -v 2
& $py -m unittest discover -s scripts -p test_demo_web_build.py -v
Push-Location frontend
flutter test --no-pub --reporter expanded test/activity_unit_test.dart
$widgets = (Get-ChildItem test/*widget_test.dart).FullName
flutter test --no-pub --reporter expanded @widgets test/responsive_shell_test.dart
Pop-Location
```

Python accepte l’identifiant positif `42` et rejette notamment `0`, `-2` et du texte. Les quatre tests de démo couvrent l’option CLI, sa transmission à ZAP, la validation du build fourni et la compilation locale. Dart transforme la quantité API `12.500` en `12.5 m³` et traite la quantité absente. Les widgets vérifient le comportement des écrans. Artefacts **unit** et **components**.

### C3 · API, intégration, fiabilité et navigateurs

```powershell
& $py scripts/test_backend.py @apps --exclude-tag unit --exclude-tag reliability -v 2
& $py scripts/test_backend.py crops.tests -k remaining_hectare -v 2
& $py scripts/test_backend.py @apps --tag reliability -v 2
& $py scripts/test_backend.py crops.test_concurrency -v 2
Push-Location frontend
flutter test --no-pub --reporter expanded test/session_error_test.dart
Pop-Location
& $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_admin_audit_keyboard_journey -v 2
```

Le premier groupe couvre notamment le CRUD, les droits, l’isolation et les filtres. Les commandes ciblées répètent volontairement certains cas pour les expliquer : avec 1 ha libre, **0,99 / 1,00 / 1,01 ha** donnent **201 / 201 / 400**. La fiabilité reprend l’écriture après échec et protège la surface concurrente. Flutter vérifie la récupération de session. Playwright rejoue la connexion admin au clavier et vérifie la ligne d’audit dans **Chromium et Firefox**. Artefacts **api**, **reliability** et **browser**.

### C4 · SAST, SCA et maintenabilité

**SAST et complexité.** Docker Desktop doit tourner pour la règle Semgrep Dart. Si Docker est indisponible pendant la soutenance, ouvrir l’artefact **sast** du run de référence.

```powershell
& $py -m bandit -r backend -x tests.py,quality_live.py,migrations,seed_demo.py -ll --exit-zero -f json -o "$out/bandit.json"
$issues = (Get-Content "$out/bandit.json" -Raw | ConvertFrom-Json).results
$issues | Select-Object test_id,issue_severity,filename,line_number
if ($issues | Where-Object issue_severity -eq 'HIGH') { throw 'Bandit a trouvé une alerte HIGH' }
& $py -m radon cc backend -s -n C -a
docker run --rm -v "${root}:/src" -w /src semgrep/semgrep:1.125.0 semgrep scan --config .github/dart-security.yml --metrics=off --error frontend/lib
Push-Location frontend
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings lib
Pop-Location
```

Le rapport local archivé signale **B310**, niveau moyen, dans le service météo. La règle Dart cherche un rappel TLS qui accepterait inconditionnellement un certificat. Radon identifie cinq blocs C ou plus dans son [rapport archivé](evidence/complexity.txt).

**SCA.** Depuis la racine, vérifier les dépendances de l’environnement actif et le verrou Pub. Le contrôle CI vérifie également la version amont de Torch, car la distribution CPU peut porter un suffixe local.

```powershell
& $py -m pip install PyYAML
& $py -c "from importlib.metadata import version; print('torch==' + version('torch').split('+')[0])" | Set-Content "$out/torch.txt" -Encoding ascii
& $py -m pip_audit --no-deps --disable-pip -r "$out/torch.txt"
& $py -m pip_audit --local --progress-spinner off
& $py scripts/audit_pub.py
```

Montrer **sca** et la [correction suivie du retest](traceability.md#course-exercises-applied-to-farm_app) : setuptools 78.1.0 signalé, exigence relevée à ≥ 84.1.0 dans la CI, contrôle réussi lors du retest. Le résultat dépend de la date et des versions auditées.

### C5 · Couverture et SonarQube

Cette mesure locale couvre la suite Django standard, les quatre tests des scripts de démo et les composants Flutter. La CI fusionne en plus les fichiers des jobs dédiés, dont le navigateur et la récupération de session. Pour citer une valeur de CI, télécharger **coverage**, ouvrir **coverage.txt**, **python.xml** ou **flutter.info** et noter le commit.

```powershell
& $py -m coverage run --data-file="$out/covdata" backend/manage.py test @apps -v 1
& $py -m coverage run --append --data-file="$out/covdata" -m unittest discover -s scripts -p test_demo_web_build.py -v
& $py -m coverage report --data-file="$out/covdata"
& $py -m coverage xml --data-file="$out/covdata" -o "$out/python.xml"
Push-Location frontend
$dart = (Get-ChildItem test/*unit_test.dart,test/*widget_test.dart).FullName
flutter test --no-pub --coverage --reporter expanded @dart test/responsive_shell_test.dart test/session_error_test.dart
Get-Item coverage/lcov.info
Pop-Location
Start-Process 'https://sonarcloud.io/project/issues?id=WasMas_Farm_App&branch=test_project&resolved=false'
```

Pour retrouver les constats actuellement ouverts et leur emplacement :

```powershell
$sonar = Invoke-RestMethod 'https://sonarcloud.io/api/issues/search?componentKeys=WasMas_Farm_App&branch=test_project&resolved=false&ps=100'
$sonar.total
$sonar.issues | Format-Table rule,status,component,line,message -Wrap
```

L’analyse elle-même s’exécute dans **SonarQube Quality Gate**, après **Rapports de couverture**, sur le backend, les scripts Python et les sources Dart. Le workflow réutilise le jeton configuré dans GitHub.

### C6 · DAST passif sur le parcours propriétaire

```powershell
& $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_unauthenticated_http_response -v 2
$zapJar = Join-Path $env:TEMP 'farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar'
Test-Path $zapJar
```

Le premier test attend **401**, `nosniff` et `DENY` sur le tableau de bord protégé. Si `Test-Path` renvoie `False`, affecter à `$zapJar` le chemin du JAR extrait de ZAP 2.17.0. Avec Java, Flutter et Chromium installés et les ports **8091/18000** libres, régénérer le rapport. Cette commande remplace le fichier local `zap-passive.json`. Pour présenter le rapport existant, passer directement au second bloc.

```powershell
& $py scripts/demo.py --passive-zap $zapJar
```

```powershell
$zap = Get-Content docs/quality/evidence/zap-passive.json -Raw | ConvertFrom-Json
$zap | Select-Object recorded_utc,zap_version,mode,alert_instances
$zap.findings | Format-Table risk,rule,path,alert -Wrap
```

Dans GitHub, ouvrir un run qui a exécuté **DAST HTTP et ZAP passif**, puis son résumé et l’artefact **zap-passive**. Le parcours observe la connexion, les fermes, le tableau de bord et la recherche dans le journal. Interpréter le résultat dans le périmètre de ces routes.

### C7 · Performance

```powershell
$env:DB_POOL = '1'
try {
    & $py scripts/test_backend.py core.quality_live.LiveQualityTests.test_dashboard_load -v 2
} finally {
    Remove-Item Env:DB_POOL -ErrorAction SilentlyContinue
}
Select-String 'Dashboard:' docs/quality/evidence/load-before-pooling.txt,docs/quality/evidence/live.txt
```

Lire le nombre de propriétaires, les réponses réussies, le débit, le p95 et la cible. Un dépassement du seuil fait échouer le test. Les deux lignes de `Select-String` donnent la comparaison **historique locale**. Le run CI qui exécute ce test fournit l’artefact **performance/load.txt**.

### C8 · Retrouver les exécutions GitHub

```powershell
Start-Process 'https://github.com/WasMas/Farm_App/actions/workflows/quality.yml?query=branch%3Atest_project'
```

Sélectionner un run par son commit. Un push sur `test_project` déclenche le workflow. Le premier job Django refait l’installation pour la portabilité, les suivants peuvent restaurer l’environnement Python. Flutter compile le web une fois par run et Sonar/ZAP récupèrent l’artefact. Ces optimisations réutilisent les outils et la compilation ; chaque test planifié s’exécute. Les rapports de la plupart des catégories sont conservés sept jours : télécharger ceux de la soutenance avant expiration.

### C9 · Exemples à expliquer au jury

Les résultats ci-dessous proviennent du [run de référence](https://github.com/WasMas/Farm_App/actions/runs/45043679144) ou des preuves locales indiquées. Un test réussit aussi lorsqu’il obtient le refus attendu.

| Test ou contrôle | Manipulation | Résultat observé |
|---|---|---|
| Identifiant de ferme · Python | Convertir `42`, puis essayer zéro, un négatif, du texte et une valeur absente. | 42 accepté. Les quatre entrées invalides déclenchent l’erreur attendue. |
| Quantité d’une activité · Dart | Lire `12.500` en mètres cubes, puis une quantité absente. | Le champ affiche `12.5 m³`, puis une chaîne vide. |
| CRUD · API et PostgreSQL | Créer, relire, modifier et supprimer ferme, parcelle, plantation et activité. | 201, mises à jour persistées, 204 puis 404 après suppression. Le groupe API a réussi ses 41 tests. |
| Limite de surface · API | Demander 0,99, 1,00 et 1,01 ha dans trois essais avec 1 ha libre. | 201, 201 et 400. [Rapport](evidence/area-boundaries.txt). |
| Écriture de l’audit · fiabilité | Faire échouer l’audit pendant la création, vérifier la base puis réessayer. | Zéro activité après la panne. À la reprise, HTTP 201 et une activité avec son audit. |
| Dernier hectare · concurrence | Deux clients demandent chacun 1 ha au même moment. | Attente sur verrou observée. Un 201, un 400 et un seul hectare alloué. [Rapport](evidence/planting-race.txt). |
| Initialisation admin · fiabilité | Exécuter deux fois la commande qui prépare l’administrateur. | Un seul superutilisateur et le même mot de passe haché après le second appel. |
| Journal · widget Flutter | Afficher une irrigation, puis chercher `unmatched` à 390 et 1 440 px. | La quantité apparaît, puis « A fresh page ». Les deux tests passent. |
| Session Flutter · fiabilité | L’API répond 401 et le service de renouvellement répond temporairement 503. | L’application conserve le jeton de renouvellement et ne marque pas la session expirée. |
| Admin · compatibilité et clavier | Se connecter au clavier et rechercher la ligne d’audit avec Playwright. | Auteur, action et entité vérifiés sur Chromium et Firefox. |
| Accès HTTP · sécurité | Consulter le tableau de bord sans authentification. | HTTP 401 et en-têtes `nosniff` et `DENY` vérifiés. |
| SAST et SCA | Analyser le code Python/Dart et les versions des dépendances Python/Pub. | Bandit relève un cas moyen, Semgrep zéro cas TLS, pip-audit aucun avis connu et OSV zéro avis pour 105 paquets. |
| ZAP · analyse passive | Observer la connexion propriétaire, le tableau de bord et la recherche du journal. | Quatre alertes faibles sur le champ `Server` et deux informatives. |
| Tableau de bord · charge | Vingt utilisateurs lisent cinq fois chacun leur tableau de bord. | 100 lectures réussies. Sur le runner, p95 de 448,9 ms sous la cible de 500 ms. |
| Installation · portabilité | Appliquer les migrations sur PostgreSQL sous Ubuntu, vérifier la santé, compiler Flutter Web. | La réponse indique PostgreSQL et la compilation produit l’artefact **flutter-web-ci**. |

## D · Quelles captures mettre sur chaque diapo ?

Le PowerPoint est projetable tel quel. Les consignes ci-dessous permettent de remplacer les preuves par celles de la répétition finale. Dans PowerPoint, utiliser **Format de l’image → Changer l’image**, ou insérer la nouvelle capture sur l’emplacement décrit. Garder le rapport, le commit ou la date associés à chaque résultat.

| Diapo | Capture et emplacement | Ce qui doit rester lisible |
|---|---|---|
| 1 · Fieldbook | À droite, le **tableau de bord Flutter connecté**, déjà intégré. | Sélecteur de ferme, bouton de saisie et indicateurs. |
| 2 · Parcours | En haut à droite, la **recherche dans le journal**. En bas, la **ligne d’audit Django**. Les captures intégrées proviennent de deux démonstrations distinctes. Pour photographier une même opération, exécuter B2 et prendre les deux vues à la suite. | Sur la première, la recherche TEK-UP et son résultat. Sur la seconde, acteur, action, entité, ID, heure. |
| 3 · Exemples unitaires et API | Les entrées et les résultats figurent sur la diapo. Pour une question, ouvrir **unit** ou **api**. | Identifiant positif, conversion de quantité et codes HTTP du CRUD. |
| 4 · Tests en direct | À la place de chacun des deux résultats, si souhaité, recadrer le **terminal 3** après chaque commande B4. | À gauche, nom du test de reprise et `OK`. À droite, largeurs 390 et 1440 et `All tests passed!`. |
| 5 · Concurrence | En bas, remplacer l’extrait par la **fin de sortie de `crops.test_concurrency`**. | Confirmation du verrou, 201, 400 et ligne de vérification en base. |
| 6 · Sécurité | À droite, remplacer le bilan ZAP par **`$zap.findings`** (§ C6) ou le tableau du job ZAP. | Alerte 10036, niveau Low, route locale et nature du header. Recadrer sur la table. |
| 7 · Sonar | Capture réelle de **Issues → test_project → All issues** au centre. | Total, fichiers, messages, priorités, statut Open et numéros de ligne. |
| 8 · Charge | Garder les mesures en grand. Si une capture est demandée, remplacer le texte du bas par les **deux lignes `Dashboard:`** de C7. | Versions avant/après, p95, seuil et nombre de requêtes. |
| 9 · Pipeline | Au centre, le graphe du run en vue agrandie. | Les cinq étapes, leurs dépendances et les résultats. |
| 10 · Bilan | Aucune capture nécessaire. En réponse à une question, ouvrir **traceability.md** et agrandir la ligne choisie. | Exigence, outil et lien vers un résultat réel. |

> [!tip] En cas de panne de réseau
> Démontrer B2 et B4 sur les services locaux. Pour GitHub et Sonar, projeter les captures du PowerPoint. Pour ZAP et la charge, ouvrir les rapports versionnés dans `docs/quality/evidence/`. Préciser « mesure archivée » en montrant ces résultats.
