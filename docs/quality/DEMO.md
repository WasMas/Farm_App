# Soutenance Farm_App — 26 novembre (10 minutes)

Fieldbook est le nom affiché par Farm_App. Le scénario suit une observation enregistrée par un propriétaire, puis consultée par un administrateur dans le journal d’audit. Les deux couches de test à lancer devant le jury sont le test API avec PostgreSQL et le test de composants Flutter.

## Avant le cours, sur ce PC Windows

Ouvrir PowerShell. PostgreSQL doit être démarré. Pour une première installation sur un autre PC, suivre [SETUP.md](../../SETUP.md) puis installer les outils ci-dessous. La compilation télécharge les dépendances si nécessaire. Les ressources de rendu seront disponibles localement.

```powershell
cd D:\Farm_App
git switch test_project
.\.venv\Scripts\python -m pip install -r backend/requirements.txt -r scripts/quality-requirements.txt
.\.venv\Scripts\python -m playwright install chromium firefox
.\.venv\Scripts\python scripts/demo.py --check
cd frontend
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/
```

## Démarrer la démonstration avant votre passage

**Terminal 1 — Django et données de démonstration**

```powershell
cd D:\Farm_App
.\.venv\Scripts\python scripts/demo.py
```

Attendre le démarrage sur le port 8000. Ce script crée une nouvelle base PostgreSQL au nom aléatoire et la remplit. Laisser le terminal ouvert. Garder à portée de main la ligne « Demo admin » affichée juste avant le démarrage du serveur.

**Terminal 2 — interface Flutter déjà compilée**

```powershell
cd D:\Farm_App
.\.venv\Scripts\python -m http.server 8080 --bind 127.0.0.1 --directory frontend/build/web
```

Ouvrir Edge à **http://localhost:8080**. Utiliser cette adresse exacte pour que l’origine du navigateur corresponde à la configuration CORS. Se connecter avec **demo_owner** et le mot de passe de démonstration **FieldbookDemo123!**. Dans un second onglet, ouvrir **http://127.0.0.1:8000/admin/core/auditevent/** et se connecter avec **demo_admin** et le mot de passe temporaire du terminal 1. Si un port est occupé, arrêter la précédente instance de démonstration.

## Pendant les 10 minutes

Le [conducteur Obsidian, section B](Soutenance.md) suit les neuf diapositives du [PowerPoint](Fieldbook-Soutenance.pptx). Préparer les terminaux avant le passage. Montrer l’observation et son audit, le graphe GitHub, puis exécuter les deux commandes ci-dessous. Pour la diapo 7, comparer le [contrôle initial](https://github.com/WasMas/Farm_App/actions/runs/45042016628) au [retest du commit 820fa5b](https://github.com/WasMas/Farm_App/actions/runs/45043679144). Le seuil est resté à 80 %, la couverture du nouveau code atteint 100 % et les 13 jobs ont réussi.

**Terminal 3 — copier les deux commandes séparément, devant le jury**

```powershell
cd D:\Farm_App
.\.venv\Scripts\python scripts/test_backend.py activities.tests.ActivityTests.test_failed_audit_rolls_back_activity_and_retry_succeeds -v 2
```

```powershell
cd D:\Farm_App\frontend
flutter test --no-pub --reporter expanded test/activities_widget_test.dart
```

**Variante si le jury demande les navigateurs ou la charge**

```powershell
cd D:\Farm_App
$env:DB_POOL = '1'
.\.venv\Scripts\python scripts/test_backend.py core.quality_live -v 2
```

À la fin, faire **Ctrl+C** dans les terminaux 2 et 1. Le terminal 1 supprime la base qu’il a créée. Une nouvelle exécution donne une nouvelle ferme de démonstration et un nouveau mot de passe administrateur.

## GitHub Actions

Ouvrir le dépôt GitHub → **Actions** → **Farm_App quality** → choisir l’exécution du commit présenté. Le graphe progresse de gauche à droite : installation, tests unitaires, intégration et fiabilité, analyses statiques, puis tests dynamiques. Les jobs d’une même étape peuvent fonctionner en parallèle. Ouvrir les étapes pour expliquer un succès ou un échec. Dans **Artifacts**, choisir le rapport de la catégorie présentée, par exemple **reliability**, **coverage**, **zap-passive** ou **performance**. Le workflow se déclenche à chaque push vers **test_project**. L’option manuelle GitHub dépend de la présence du workflow sur la branche par défaut.

Pour reproduire la suite Django standard sur ce PC: depuis la racine, exécuter ` .\.venv\Scripts\python scripts/test_backend.py -v 2`. Les trois tests de serveur réel sont dans la commande de variante ci-dessus. Les commandes de couverture, de complexité, d’analyse statique et d’analyse des dépendances figurent dans [quality.yml](../../.github/workflows/quality.yml).

## Bonus — deux demandes pour le dernier hectare

Depuis la racine du projet, lancer ce test dans le terminal 3 :

```powershell
.\.venv\Scripts\python scripts/test_backend.py crops.test_concurrency -v 2
```

« Alice et Bob ont tous les deux le droit de planter. Ils demandent chacun le dernier hectare de la même parcelle. Le test maintient brièvement le verrou pour observer la seconde transaction en attente dans PostgreSQL. Une fois le verrou libéré, la seconde demande vérifie à nouveau la surface disponible. »

Montrer **HTTP 201** (plantation créée), **HTTP 400** (surface insuffisante), puis la vérification en base : **une seule plantation d’un hectare**. Alice ou Bob peut réussir. [Exécution enregistrée](evidence/planting-race.txt).

## Compléments du cours — limites, analyse passive et retest

**Valeurs limites.** Depuis la racine du dépôt, lancer les trois cas indépendants :

```powershell
.\.venv\Scripts\python scripts/test_backend.py crops.tests -k remaining_hectare -v 2
```

« Il reste exactement 1 hectare. On essaie juste en dessous, exactement à la limite, puis juste au-dessus. La limite est inclusive : 0,99 et 1,00 passent, 1,01 est refusé. » [Résultats enregistrés](evidence/area-boundaries.txt)

**TP3 — ZAP passif.** Pour la présentation, ouvrir le [rapport des routes et alertes](evidence/zap-passive.json). Pour le régénérer sur ce PC, garder PostgreSQL actif et les ports 8091 et 18000 disponibles. La commande crée une base jetable, compile l’interface, démarre ZAP en mode sûr, puis ouvre le parcours propriétaire dans Chromium. Elle utilise Java, Flutter, Playwright et la distribution multiplateforme ZAP 2.17.0. Sur un autre PC, remplacer le chemin du JAR par celui de sa distribution extraite.

```powershell
cd D:\Farm_App
$zapJar = Join-Path $env:TEMP 'farm-zap-tool\ZAP_2.17.0\zap-2.17.0.jar'
.\.venv\Scripts\python scripts/demo.py --passive-zap $zapJar
```

**TP4 — correction et retest.** Ouvrir la ligne SCA dans la [matrice](traceability.md) : montrer le premier contrôle de dépendances en échec, la mise à jour de setuptools, puis le contrôle réussi sur GitHub.

**ZAP sur GitHub.** Dans Actions → Farm_App quality, ouvrir une exécution puis sa page Summary. Le tableau **Farm_App passive ZAP findings** affiche la gravité, la règle, l’alerte et la route. Le job **DAST HTTP et ZAP passif** exécute le parcours sur une base jetable. Le rapport JSON de cette exécution se télécharge dans **Artifacts → zap-passive**.


## Activer SonarQube Cloud gratuitement

1. Se connecter à [SonarQube Cloud EU](https://sonarcloud.io) avec GitHub. Choisir une organisation sur le plan **Free**, un projet public pour Farm_App et la méthode d’analyse **GitHub Actions / CI**. Désactiver l’analyse automatique du projet si elle est active.
2. Le plan Free analyse une branche principale. Utiliser **test_project** comme branche principale du **projet Sonar**. Vérifier ce nom dans la configuration du projet avant le premier push analysé. La branche par défaut du dépôt GitHub peut rester main. Utiliser le Quality Gate intégré **Sonar way**. [Limites des plans](https://docs.sonarsource.com/sonarqube-cloud/administering-sonarcloud/managing-subscription/subscription-plans)
3. Copier les clés exactes de l’organisation et du projet depuis Sonar. Créer un jeton autorisé à analyser le projet. Dans GitHub → Settings → Secrets and variables → Actions, ajouter le secret **SONAR_TOKEN**, puis les variables **SONAR_ORGANIZATION** et **SONAR_PROJECT_KEY**. Ajouter la clé du projet en dernier : elle active le job. Conserver le jeton uniquement dans les secrets GitHub.
4. Déclencher un push sur test_project. Le job Sonar récupère les rapports de couverture Python et Dart, analyse les deux sources et attend le verdict. Tant que la clé du projet manque, GitHub affiche **Skipped** pour Sonar et exécute les autres contrôles. Après activation, un échec de l’analyse ou du Quality Gate bloque les jobs dynamiques. Les PR externes et Dependabot ne reçoivent pas le jeton.
