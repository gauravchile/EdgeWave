#!/usr/bin/env bash
set -euo pipefail

BASE_DIR=${1:-"manifests/base"}
APP_PREFIX=${2:-"edgewave"}

# ------------------------------------------------------------------------------
# DETECT CURRENT COLOR FROM FRONTEND SERVICE YAML
# ------------------------------------------------------------------------------
FRONTEND_SVC="${BASE_DIR}/frontend-svc.yaml"

if [[ ! -f "$FRONTEND_SVC" ]]; then
  echo "❌ Frontend service file not found: $FRONTEND_SVC"
  exit 1
fi

CURRENT_COLOR=$(grep -E "color:" "$FRONTEND_SVC" | awk '{print $2}' | head -n1 || echo "blue")
NEW_COLOR="green"
if [[ "$CURRENT_COLOR" == "green" ]]; then
  NEW_COLOR="blue"
fi

echo "🔄 Current active color: $CURRENT_COLOR"
echo "🎯 Switching traffic to: $NEW_COLOR"

# ------------------------------------------------------------------------------
# UPDATE SERVICE MANIFESTS LOCALLY
# ------------------------------------------------------------------------------
for resource in frontend backend; do
  SVC_FILE="${BASE_DIR}/${resource}-svc.yaml"
  if [[ -f "$SVC_FILE" ]]; then
    echo "📝 Updating $SVC_FILE → color: $NEW_COLOR"
    sed -i -E "s/color: (blue|green)/color: ${NEW_COLOR}/g" "$SVC_FILE"
  else
    echo "⚠️  Missing service file: $SVC_FILE (skipped)"
  fi
done

echo "✅ Updated local manifests to color: $NEW_COLOR"
