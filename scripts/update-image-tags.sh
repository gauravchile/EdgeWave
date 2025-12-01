#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./update-image-tags.sh <base_dir> <image_repo> <backend_tag> <frontend_tag> <color>
#
# Example:
# ./update-image-tags.sh manifests/base docker.io/gaurav/shieldops v1.2.3 v1.2.3 blue

BASE_DIR=${1:-manifests/base}
IMAGE_REPO=${2:?"image repo required"}
BACKEND_TAG=${3:?"backend tag required"}
FRONTEND_TAG=${4:?"frontend tag required"}
COLOR=${5:?"deployment color required (blue|green)"}

if [[ "$COLOR" != "blue" && "$COLOR" != "green" ]]; then
  echo "❌ Invalid color: $COLOR (must be 'blue' or 'green')" >&2
  exit 1
fi

echo "🔧 Updating image tags for $COLOR deployment in $BASE_DIR ..."
echo "   Backend → ${IMAGE_REPO}:${BACKEND_TAG}"
echo "   Frontend → ${IMAGE_REPO}:${FRONTEND_TAG}"

# Strip "docker.io/" prefix if present
REPO_SHORT=$(echo "$IMAGE_REPO" | sed 's|^docker\.io/||')

# Define file paths
BACKEND_FILE="$BASE_DIR/backend-deploy-${COLOR}.yaml"
FRONTEND_FILE="$BASE_DIR/frontend-deploy-${COLOR}.yaml"

# Update backend image
if [[ -f "$BACKEND_FILE" ]]; then
  sed -E -i.bak \
    "s|(image:\s*)${REPO_SHORT}:backend-${COLOR}-[a-zA-Z0-9._:-]+|\1${REPO_SHORT}:${BACKEND_TAG}|g" \
    "$BACKEND_FILE" && rm -f "$BACKEND_FILE.bak"
  echo "✅ Updated backend image in $BACKEND_FILE"
else
  echo "⚠️  Backend file not found: $BACKEND_FILE"
fi

# Update frontend image
if [[ -f "$FRONTEND_FILE" ]]; then
  sed -E -i.bak \
    "s|(image:\s*)${REPO_SHORT}:frontend-${COLOR}-[a-zA-Z0-9._:-]+|\1${REPO_SHORT}:${FRONTEND_TAG}|g" \
    "$FRONTEND_FILE" && rm -f "$FRONTEND_FILE.bak"
  echo "✅ Updated frontend image in $FRONTEND_FILE"
else
  echo "⚠️  Frontend file not found: $FRONTEND_FILE"
fi

echo "🎉 Done! Updated image tags for $COLOR environment."
