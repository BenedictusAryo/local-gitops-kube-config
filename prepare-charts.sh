#!/bin/bash
# prepare-charts.sh
# A script to prepare the charts directory structure for development

echo -e "\033[0;36mPreparing Helm charts for development...\033[0m"

# Create necessary directories for infrastructure chart dependencies
declare -a INFRA_CHART_DIRS=(
    "./charts/infrastructure/charts/ingress-nginx"
    "./charts/infrastructure/charts/postgresql"
    "./charts/infrastructure/charts/argo-cd"
)

for dir in "${INFRA_CHART_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "\033[0;33mCreating directory: $dir\033[0m"
        mkdir -p "$dir"
        # Add a .gitkeep file to ensure the directory is tracked by git
        touch "$dir/.gitkeep"
    fi
done

# Create necessary directories for application chart dependencies
declare -a APP_CHART_DIRS=(
    "./charts/applications/charts/fastapi-app"
)

for dir in "${APP_CHART_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "\033[0;33mCreating directory: $dir\033[0m"
        mkdir -p "$dir"
        # Add a .gitkeep file to ensure the directory is tracked by git
        touch "$dir/.gitkeep"
    fi
done

# Add Helm repositories
echo -e "\033[0;33mAdding required Helm repositories...\033[0m"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Build chart dependencies
echo -e "\033[0;33mBuilding chart dependencies...\033[0m"
if helm dependency build ./charts/infrastructure; then
    echo -e "\033[0;32mInfrastructure chart dependencies built successfully.\033[0m"
else
    echo -e "\033[0;33mWarning: Failed to build infrastructure chart dependencies. You may need to install them manually.\033[0m"
fi

if helm dependency build ./charts/applications; then
    echo -e "\033[0;32mApplications chart dependencies built successfully.\033[0m"
else
    echo -e "\033[0;33mWarning: Failed to build applications chart dependencies. You may need to install them manually.\033[0m"
fi

echo -e "\033[0;32mCharts preparation completed!\033[0m"
