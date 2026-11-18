# Run this from the repository root after reviewing the ML/recommendation changes.
# This script does not add a GitHub/Copilot co-author trailer.

$branch = "feature/ml-recommendations-predictions"

git status
git switch main
git pull --ff-only origin main
git switch -c $branch

# Stage only ML, recommendation, prediction, and their model dependencies.
git add backend/recommendations
git add backend/predictions
git add backend/crops/models.py
git add backend/crops/serializers.py
git add backend/crops/migrations/0003_croptype_reference_data.py
git add backend/config/settings.py
git add backend/config/urls.py
git add backend/requirements.txt
git add frontend/lib/features/recommendations
git add frontend/lib/features/predictions
git add frontend/lib/core/router.dart
git add frontend/lib/core/widgets/farm_shell.dart

git status
git diff --cached --check
git diff --cached --stat
git commit -m "feat(ml): add agricultural recommendations and disease predictions"
git push --set-upstream origin $branch

Write-Host "Pushed $branch. Create the pull request from this branch in GitHub."
