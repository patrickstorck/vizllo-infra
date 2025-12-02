#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

# Files directly under repository root (excluding env files)
mapfile -t ROOT_FILES < <(
  find . -maxdepth 1 -type f \
    ! -name ".env" \
    ! -name ".env.*" \
    ! -name ".DS_Store" \
    -print
)

# Directories allowed to stage from root (avoid backend/ and frontend/)
ALLOWED_DIRS=("scripts")

TO_STAGE=()
TO_STAGE+=("${ROOT_FILES[@]}")

for dir in "${ALLOWED_DIRS[@]}"; do
  if [[ -d "$dir" ]]; then
    TO_STAGE+=("$dir")
  fi
done

if [[ ${#TO_STAGE[@]} -eq 0 ]]; then
  echo "Nothing to stage at repository root."
  exit 1
fi

read -rp "Commit message: " COMMIT_MSG
if [[ -z "${COMMIT_MSG// }" ]]; then
  echo "Commit message cannot be empty."
  exit 1
fi

echo "==> Ensuring dev branch"
git fetch origin || true
if git show-ref --verify --quiet refs/heads/dev; then
  git checkout dev
else
  git checkout -b dev origin/main 2>/dev/null || git checkout -b dev main
fi

echo "==> Staging root files (excluding backend/frontend)"
git add "${TO_STAGE[@]}"

echo "==> Committing"
git commit -m "$COMMIT_MSG"

echo "==> Pushing to dev"
git push -u origin dev

echo "==> Switching to main and back to dev"
git checkout main
git checkout dev

echo "All done."
