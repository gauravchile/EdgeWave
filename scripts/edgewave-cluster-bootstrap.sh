#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME=${CLUSTER_NAME:-edgewave-eks}
REGION=${REGION:-ap-south-1}
NODE_TYPE=${NODE_TYPE:-t3.medium}
NODE_COUNT=${NODE_COUNT:-2}
K8S_VERSION=${K8S_VERSION:-1.29}

eksctl create cluster --name "$CLUSTER_NAME" --region "$REGION" \
  --version "$K8S_VERSION" --nodegroup-name ng-default \
  --nodes "$NODE_COUNT" --node-type "$NODE_TYPE" --managed

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "Port-forward UI: kubectl -n argocd port-forward svc/argocd-server 8080:80"
