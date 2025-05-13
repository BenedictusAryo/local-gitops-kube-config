#!/bin/bash
# update-gitops-config.sh
# A script to update the GitOps configuration in an existing environment

# Default to pushing changes
SKIP_PUSH=false

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-push) SKIP_PUSH=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo -e "\033[0;36mUpdating GitOps configuration...\033[0m"

# Step 1: Check if the cluster exists
echo -e "\033[0;33mChecking Kind cluster...\033[0m"
if ! kind get clusters | grep -q "local-gitops-cluster"; then
    echo -e "\033[0;31mCluster 'local-gitops-cluster' does not exist. Please run bootstrap-local-gitops.sh first.\033[0m"
    exit 1
fi

# Step 2: Set kubectl context
kubectl config use-context kind-local-gitops-cluster

# Step 3: Check if ArgoCD is running
if ! kubectl get deployments -n argocd -l app.kubernetes.io/name=argocd-server -o name &> /dev/null; then
    echo -e "\033[0;31mArgoCD is not running. Please run bootstrap-local-gitops.sh first.\033[0m"
    exit 1
fi

# Step 4: Check bootstrap chart
if ! kubectl get deployments -n argocd -l app.kubernetes.io/instance=bootstrap -o name &> /dev/null; then
    echo -e "\033[0;33mBootstrap chart is not installed. Installing now...\033[0m"
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
else
    echo -e "\033[0;33mUpgrading bootstrap chart...\033[0m"
    helm upgrade bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
fi

# Step 5: Verify Helm charts
echo -e "\033[0;33mVerifying Helm charts...\033[0m"
./verify-helm-charts.sh

if [ "$SKIP_PUSH" = false ]; then
    # Step 6: Commit and push changes (if git is available)
    if command -v git &> /dev/null; then
        echo -e "\033[0;33mCommitting and pushing changes...\033[0m"
        
        # Check if there are changes to commit
        if [ -n "$(git status --porcelain)" ]; then
            read -p "Enter commit message: " COMMIT_MESSAGE
            if [ -z "$COMMIT_MESSAGE" ]; then
                COMMIT_MESSAGE="Update GitOps configuration"
            fi
            
            git add .
            git commit -m "$COMMIT_MESSAGE"
            git push
            
            echo -e "\033[0;32mChanges pushed to repository. ArgoCD will automatically sync.\033[0m"
        else
            echo -e "\033[0;32mNo changes to commit.\033[0m"
        fi
    else
        echo -e "\033[0;33mGit command not found. Skipping commit and push.\033[0m"
    fi
fi

# Step 7: Force sync applications if needed
read -p "Do you want to force sync ArgoCD applications? (y/N): " FORCE_SYNC_APPS
if [[ "$FORCE_SYNC_APPS" =~ ^[Yy]$ ]]; then
    # Check if ArgoCD CLI is available
    if command -v argocd &> /dev/null; then
        # Get argocd password
        PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null)
        if [ -n "$PASSWORD" ]; then
            PASSWORD=$(echo "$PASSWORD" | base64 -d)
            
            # Login to ArgoCD
            argocd login localhost:8080 --username admin --password "$PASSWORD" --insecure
            
            # Force sync apps
            argocd app sync infrastructure --force
            argocd app sync applications --force
            
            echo -e "\033[0;32mApplications synced successfully.\033[0m"
        else
            echo -e "\033[0;33mCould not get ArgoCD password. Please sync applications manually through the UI.\033[0m"
        fi
    else
        echo -e "\033[0;33mArgoCD CLI not found. Please sync applications through the ArgoCD UI.\033[0m"
        echo -e "\033[0;32mAccess ArgoCD UI at https://localhost:8080\033[0m"
    fi
fi

echo -e "\033[0;36mUpdate complete!\033[0m"
echo -e "\033[0;32mYou can access the ArgoCD UI at https://localhost:8080\033[0m"
