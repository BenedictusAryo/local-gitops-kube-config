#!/bin/bash
# verify-helm-charts.sh
# A script to verify the Helm charts in this repository

# Default to dev environment if not specified
ENVIRONMENT=${1:-dev}

echo -e "\033[0;36mVerifying Helm charts in the repository for environment: $ENVIRONMENT...\033[0m"

# Verify the infrastructure chart
echo -e "\033[0;33mVerifying infrastructure chart...\033[0m"
echo -e "Adding required Helm repositories..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create a temporary directory for chart dependencies
if [ ! -d "tmp" ]; then
    mkdir -p "tmp"
fi

# Check if environment exists
if [ ! -d "./environments/$ENVIRONMENT" ]; then
    echo -e "\033[0;31mEnvironment $ENVIRONMENT not found!\033[0m"
    echo -e "\033[0;37mAvailable environments:\033[0m"
    for env in ./environments/*/; do
        echo -e "- $(basename "$env")"
    done
    exit 1
fi

# Build infrastructure chart dependencies
INFRASTRUCTURE_CHART_PATH="./charts/infrastructure"
echo -e "\033[0;33mBuilding dependencies for infrastructure chart...\033[0m"

# Try to build dependencies but don't fail if repositories are not available
if helm dependency build "$INFRASTRUCTURE_CHART_PATH"; then
    INFRA_DEPS_BUILT=true
else
    echo -e "\033[0;33mWarning: Could not build all dependencies for infrastructure chart. Some validations may fail.\033[0m"
    INFRA_DEPS_BUILT=false
fi

# Verify infrastructure chart
echo -e "\033[0;33mValidating infrastructure chart with $ENVIRONMENT environment values...\033[0m"
if [ "$INFRA_DEPS_BUILT" = true ]; then
    helm template --debug infra "$INFRASTRUCTURE_CHART_PATH" -f "./environments/$ENVIRONMENT/infra-values.yaml"
else
    echo -e "\033[0;33mSkipping template validation for infrastructure chart due to missing dependencies.\033[0m"
fi

# Verify applications chart
APPLICATIONS_CHART_PATH="./charts/applications"
echo -e "\033[0;33mValidating applications chart with $ENVIRONMENT environment values...\033[0m"
helm template --debug apps "$APPLICATIONS_CHART_PATH" -f "./environments/$ENVIRONMENT/apps-values.yaml"

# Verify bootstrap chart
BOOTSTRAP_CHART_PATH="./charts/bootstrap"
echo -e "\033[0;33mValidating bootstrap chart with $ENVIRONMENT environment values...\033[0m"
helm template --debug bootstrap "$BOOTSTRAP_CHART_PATH" -f "./environments/$ENVIRONMENT/bootstrap-values.yaml"

# Verify that ArgoCD can properly parse application manifests
echo -e "\033[0;33mValidating ArgoCD application manifests...\033[0m"
kubectl apply --validate=true --dry-run=client -f ./manifests/infra-app.yaml
kubectl apply --validate=true --dry-run=client -f ./manifests/apps-app.yaml

# Check for lint issues
echo -e "\033[0;33mLinting Helm charts...\033[0m"
# Only check the bootstrap chart syntax as it doesn't have dependencies that need to be fetched
helm lint "$BOOTSTRAP_CHART_PATH" -f "./environments/$ENVIRONMENT/bootstrap-values.yaml"

# Skip linting for charts that have dependencies for now
echo -e "\033[0;33mNote: Skipping full linting for charts with dependencies. Run 'helm dependency build' before deploying.\033[0m"

echo -e "\033[0;32mVerification for $ENVIRONMENT environment completed!\033[0m"
echo -e "\033[0;36mTo verify a different environment, run: ./verify-helm-charts.sh <env-name>\033[0m"
