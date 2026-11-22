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
flutter pub get
flutter build web --release --no-web-resources-cdn
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

| Temps | Manipulation et explication |
|---|---|
| 0–1 min | Montrer le tableau de bord. « Un propriétaire gère ses parcelles, ses plantations et les interventions. Les ouvriers agissent sur les parcelles affectées. L’administrateur contrôle les accès et l’audit. » |
| 1–3 min | Choisir une ferme dans le sélecteur du tableau de bord. Cliquer sur **Record today’s work**, choisir l’observation, une plantation active et la date du jour. Saisir **TEK-UP feuilles saines** et enregistrer. Ouvrir **All records** et rechercher **TEK-UP**. |
| 3–4 min | Actualiser l’onglet administrateur. Montrer la dernière ligne **activities.Activity**, l’action **create**, le propriétaire, l’identifiant de l’objet et l’heure. |
| 4–6 min | Exécuter la commande API ci-dessous. « Le test provoque une panne d’audit. Il vérifie que rien n’a été enregistré à moitié, puis réessaie et vérifie l’activité et son audit. » Montrer le nom du test et **OK**. |
| 6–7 min | Exécuter le test Flutter ci-dessous. « Le même historique peut être recherché sur téléphone et sur ordinateur. » Montrer les largeurs **390** et **1440** et les deux succès. |
| 7–9 min | Ouvrir la [matrice](traceability.md), puis les rapports de charge, de couverture et de sécurité. Expliquer que p95 est le temps que 95 % des réponses respectent. Préciser la taille du jeu de données et le seul avertissement Bandit restant. |
| 9–10 min | Montrer l’exécution GitHub Actions et ses artefacts si disponibles. Expliquer qu’un nouveau commit relance les vérifications. Garder les rapports locaux ouverts pour la présentation sans réseau. |

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

Ouvrir le dépôt GitHub → **Actions** → **Farm_App quality** → choisir l’exécution du commit présenté. Les jobs **backend** et **flutter** s’exécutent en parallèle. Ouvrir les étapes pour expliquer un succès ou un échec. Dans **Artifacts**, télécharger **backend-quality** et **flutter-quality**. Le workflow se déclenche à chaque push vers **test_project**. L’option manuelle GitHub dépend de la présence du workflow sur la branche par défaut.

Pour reproduire la suite Django standard sur ce PC: depuis la racine, exécuter ` .\.venv\Scripts\python scripts/test_backend.py -v 2`. Les trois tests de serveur réel sont dans la commande de variante ci-dessus. Les commandes de couverture, de complexité, d’analyse statique et d’analyse des dépendances figurent dans [quality.yml](../../.github/workflows/quality.yml).

## Bonus — deux demandes pour le dernier hectare

Depuis la racine du projet, lancer ce test dans le terminal 3 :

```powershell
.\.venv\Scripts\python scripts/test_backend.py crops.test_concurrency -v 2
```

« Alice et Bob ont tous les deux le droit de planter. Ils demandent chacun le dernier hectare de la même parcelle. Le test maintient brièvement le verrou pour observer la seconde transaction en attente dans PostgreSQL. Une fois le verrou libéré, la seconde demande vérifie à nouveau la surface disponible. »

Montrer **HTTP 201** (plantation créée), **HTTP 400** (surface insuffisante), puis la vérification en base : **une seule plantation d’un hectare**. Alice ou Bob peut réussir. [Exécution enregistrée](evidence/planting-race.txt).
