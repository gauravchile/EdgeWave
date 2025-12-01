# =========================================================
# 🛡️ EdgeWave DevSecOps Makefile
# Author: Gaurav Chile
# =========================================================

# ---------- Global Configuration ----------
IMAGE_REPO ?= docker.io/gauravchile/edgewave
REGION ?= ap-south-1
COLOR ?= blue                  # blue | green
VERSION ?= v1.0.0              # semantic or pipeline version
TAG ?= $(shell date +%Y%m%d-%H%M%S)  # auto timestamp tag

FRONTEND_TAG := frontend-$(COLOR)-$(VERSION)
BACKEND_TAG  := backend-$(COLOR)-$(VERSION)
FRONTEND_IMAGE := $(IMAGE_REPO):$(FRONTEND_TAG)
BACKEND_IMAGE  := $(IMAGE_REPO):$(BACKEND_TAG)

NAMESPACE ?= edgewave
APP_NAME ?= edgewave-ingress

# =========================================================
# 🔧 Environment Setup
# =========================================================
prequs:
	sudo bash scripts/edgewave-prereq-install.sh

cluster-bootstrap:
	bash scripts/edgewave-cluster-bootstrap.sh

# =========================================================
# 🧰 Local Utilities
# =========================================================
sonarqube-up:
	docker compose -f compose/sonarqube.yml up -d

argocd-port:
	kubectl -n argocd port-forward svc/argocd-server 8080:80

show-images:
	@echo "-------------------------------------------"
	@echo "Frontend Image: $(FRONTEND_IMAGE)"
	@echo "Backend Image:  $(BACKEND_IMAGE)"
	@echo "-------------------------------------------"

# =========================================================
# 🐳 Docker Build & Push
# =========================================================
build-frontend:
	@echo "\n🚧 Building Frontend image: $(FRONTEND_IMAGE)"
	docker build -t $(FRONTEND_IMAGE) -f frontend/Dockerfile frontend

build-backend:
	@echo "\n🚧 Building Backend image: $(BACKEND_IMAGE)"
	docker build -t $(BACKEND_IMAGE) -f backend/Dockerfile backend

push-frontend:
	@echo "\n📤 Pushing Frontend image → Docker Hub"
	docker push $(FRONTEND_IMAGE)

push-backend:
	@echo "\n📤 Pushing Backend image → Docker Hub"
	docker push $(BACKEND_IMAGE)

# Combined targets
build-push-frontend: build-frontend push-frontend
build-push-backend: build-backend push-backend

build-push-all: build-frontend build-backend push-frontend push-backend
	@echo "\n✅ All images built and pushed successfully!"

# =========================================================
# 🔄 K8s Deployment
# =========================================================

deploy:
	kubectl apply -k manifests/overlays/prod/

remove:
	kubectl delete ns edgewave


# =========================================================
# 🔄 GitOps / CI-CD Utilities
# =========================================================
update-kustomize:
	@echo "\n📝 Updating Kustomize manifests with new image tags..."
	yq e -i '.images[0].newTag = "$(FRONTEND_TAG)"' manifests/base/kustomization.yaml
	yq e -i '.images[1].newTag = "$(BACKEND_TAG)"' manifests/base/kustomization.yaml
	git add manifests/base/kustomization.yaml
	git commit -m "Update images → frontend=$(FRONTEND_TAG), backend=$(BACKEND_TAG)"
	git push
	@echo "✅ GitOps repo updated — ArgoCD will auto-sync."

# =========================================================
# 🚀 Blue/Green Deployment Controls
# =========================================================
switch-blue:
	NAMESPACE=$(NAMESPACE) bash scripts/switch-blue-green.sh frontend blue

switch-green:
	NAMESPACE=$(NAMESPACE) bash scripts/switch-blue-green.sh frontend green

# =========================================================
# 🧠 Deploy to Production (Automated)
# =========================================================
deploy-prod: build-push-all update-kustomize switch-$(COLOR) verify-alb
	@echo "\n🚀 Deployment to production complete!"
	@echo "✅ $(COLOR) version $(VERSION) is now live."

# =========================================================
# ✅ ALB Health Verification
# =========================================================
verify-alb:
	@echo "\n🔍 Verifying ALB target group health..."
	@ALB_NAME=$$(kubectl -n $(NAMESPACE) get ingress $(APP_NAME) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'); \
	if [ -z "$$ALB_NAME" ]; then \
	  echo "❌ ALB not yet provisioned. Run 'kubectl get ingress -n $(NAMESPACE)' again in 1-2 min."; \
	  exit 1; \
	fi; \
	echo "🌐 ALB Detected: $$ALB_NAME"; \
	LB_ARN=$$(aws elbv2 describe-load-balancers --names "$$(basename $$ALB_NAME .elb.amazonaws.com)" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true); \
	if [ -z "$$LB_ARN" ]; then echo "⚠️ Could not fetch ALB ARN automatically, please verify manually."; exit 1; fi; \
	TG_ARN=$$(aws elbv2 describe-target-groups --load-balancer-arn $$LB_ARN --query 'TargetGroups[0].TargetGroupArn' --output text); \
	echo "🎯 Checking target health for: $$TG_ARN"; \
	aws elbv2 describe-target-health --target-group-arn $$TG_ARN --query 'TargetHealthDescriptions[*].TargetHealth.State' --output text

# =========================================================
# 🧹 Cleanup
# =========================================================
clean:
	docker system prune -af --volumes
	@echo "🧼 Docker cleaned up successfully."

# =========================================================
# 📦 Default Help
# =========================================================
help:
	@echo ""
	@echo "EdgeWave DevSecOps Commands"
	@echo "-------------------------------------------"
	@echo "make prequs                  # Install dependencies"
	@echo "make cluster-bootstrap       # Bootstrap EKS cluster"
	@echo "make build-push-all COLOR=blue VERSION=v1.0.0   # Build & push Docker images"
	@echo "make update-kustomize        # Update manifests for ArgoCD"
	@echo "make switch-blue             # Switch live traffic to blue deployment"
	@echo "make switch-green            # Switch live traffic to green deployment"
	@echo "make verify-alb              # Check ALB target group health"
	@echo "make deploy-prod COLOR=blue VERSION=v1.0.0      # Full automated pipeline"
	@echo "make argocd-port             # Forward ArgoCD dashboard to localhost:8080"
	@echo "make clean                   # Prune Docker system"
	@echo "-------------------------------------------"
