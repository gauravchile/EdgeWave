#!/usr/bin/env bash
set -e

MANIFEST_DIR=$1
NAMESPACE=$2

# Detect next color from Jenkins ENV
NEXT_COLOR=${NEXT_COLOR:-green}

echo "Switching Service selector to color: $NEXT_COLOR in namespace: $NAMESPACE"

# Patch service in cluster
kubectl patch svc edgewave-frontend -n "$NAMESPACE" \
  -p "{\"spec\":{\"selector\":{\"app\":\"edgewave-frontend\",\"color\":\"$NEXT_COLOR\",\"track\":\"$NEXT_COLOR\"}}}"

# Do the same for backend service if it exists
kubectl patch svc edgewave-backend -n "$NAMESPACE" \
  -p "{\"spec\":{\"selector\":{\"app\":\"edgewave-backend\",\"color\":\"$NEXT_COLOR\",\"track\":\"$NEXT_COLOR\"}}}" || true

# Update the manifests for GitOps sync
yq e -i ".spec.selector.color = \"$NEXT_COLOR\"" "$MANIFEST_DIR/frontend-service.yaml"
yq e -i ".spec.selector.track = \"$NEXT_COLOR\"" "$MANIFEST_DIR/frontend-service.yaml"
yq e -i ".spec.selector.color = \"$NEXT_COLOR\"" "$MANIFEST_DIR/backend-service.yaml"
yq e -i ".spec.selector.track = \"$NEXT_COLOR\"" "$MANIFEST_DIR/backend-service.yaml"

echo "Traffic switched to $NEXT_COLOR."
