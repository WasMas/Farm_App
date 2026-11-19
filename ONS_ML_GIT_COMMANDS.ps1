# Run this from the repository root after reviewing the ML/recommendation changes.
# This script creates small conventional commits and does not add an author trailer.

$branch = "feature/ml-recommendations-predictions"

function Commit-Paths {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string[]]$Paths
    )

    git add -- @Paths
    $staged = @(git diff --cached --name-only)
    if ($staged.Count -gt 0) {
        git diff --cached --check
        git commit -m $Message
    }
    else {
        Write-Host "Skipping: no staged changes for $Message"
    }
}

git status
git fetch origin
git switch main
git switch -c $branch

Commit-Paths "build(deps): add pretrained disease model dependencies" @(
    "backend/requirements.txt"
)

Commit-Paths "feat(crops): add soil suitability and stage timing" @(
    "backend/crops/models.py",
    "backend/crops/serializers.py",
    "backend/crops/migrations/0003_croptype_reference_data.py"
)

Commit-Paths "feat(recommendations): add farm recommendation engine" @(
    "backend/recommendations"
)

Commit-Paths "feat(predictions): add pretrained disease classifier" @(
    "backend/predictions"
)

Commit-Paths "feat(demo): add resettable presentation dataset" @(
    "backend/core/management"
)

Commit-Paths "feat(ui): add farm recommendation screen" @(
    "frontend/lib/features/recommendations"
)

Commit-Paths "feat(ui): add disease and yield prediction screens" @(
    "frontend/lib/features/predictions"
)

Commit-Paths "feat(app): integrate ML routes and navigation" @(
    "backend/config/settings.py",
    "backend/config/urls.py",
    "frontend/lib/core/router.dart",
    "frontend/lib/core/widgets/farm_shell.dart"
)

git status
git push --set-upstream origin $branch

Write-Host "Pushed $branch with small conventional commits. Create the pull request in GitHub."
