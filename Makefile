CLUSTER ?= laptop

.PHONY: argocd
argocd: ## deploy argocd with helm
	@helm upgrade --install argocd argo-cd --repo https://argoproj.github.io/argo-helm --namespace argocd --create-namespace --values ./scripts/values.argocd.yaml > /dev/null

argocd-credentials: ## print the argocd admin credentials
	@echo "    Username: admin\n    Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

grafana-credentials: ## print the grafana admin credentials
	@echo "    Username: admin\n    Password: prom-operator"

## --------------------------------------
## k3d
## --------------------------------------

bootstrap-k3d: ## bootstrap an opinionated k3d cluster
	@./scripts/bootstrap.sh start-k3d

start-k3d: ## setup k3d cluster
	@CLUSTER="${CLUSTER}" ./scripts/setup_k3d.sh

destroy-k3d: ## destroy k3d cluster
	@k3d cluster delete "${CLUSTER}"

## --------------------------------------
## terraform
## --------------------------------------

tf-plan: ## plan terraform resources
	@terraform -chdir=infrastructure plan -var-file terraform.tfvars

tf-apply: ## apply terraform resources
	@terraform -chdir=infrastructure apply -var-file terraform.tfvars -auto-approve

## --------------------------------------
## kind
## --------------------------------------

bootstrap-kind: ## bootstrap an opinionated kind cluster
	@./scripts/bootstrap.sh start-kind

start-kind: ## setup kind cluster
	@CLUSTER="${CLUSTER}" ./scripts/setup_kind.sh

destroy-kind: ## destroy kind cluster
	@kind delete cluster --name "${CLUSTER}"

## --------------------------------------
## tooling
## --------------------------------------

## Self documented: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## available make commands
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' ./Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
