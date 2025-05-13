#!/bin/bash
# bootstrap-local-gitops.sh
# A script to bootstrap the local GitOps environment

echo -e "\033[0;36mBootstrapping local GitOps environment...\033[0m"

# Step 1: Check prerequisites
echo -e "\033[0;33mChecking prerequisites...\033[0m"
prerequisites=("docker" "kind" "kubectl" "helm")
missing=()

for tool in "${prerequisites[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing+=("$tool")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo -e "\033[0;31mMissing required tools: ${missing[*]}\033[0m"
    echo -e "\033[0;31mPlease install these tools before continuing.\033[0m"
    exit 1
fi

# Step 1.5: Prepare charts
echo -e "\033[0;33mPreparing Helm charts...\033[0m"
./prepare-charts.sh

# Step 2: Create Kind cluster if it doesn't exist
echo -e "\033[0;33mCreating Kind cluster...\033[0m"
if ! kind get clusters | grep -q "local-gitops-cluster"; then
    kind create cluster --config=local-cluster-deployment.yaml
else
    echo -e "\033[0;32mCluster 'local-gitops-cluster' already exists, skipping creation.\033[0m"
fi

# Step 3: Set kubectl context
kubectl config use-context kind-local-gitops-cluster

# Step 4: Create ArgoCD namespace
echo -e "\033[0;33mCreating ArgoCD namespace...\033[0m"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 5: Add Helm repositories
echo -e "\033[0;33mAdding Helm repositories...\033[0m"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Step 6: Install ArgoCD
echo -e "\033[0;33mInstalling ArgoCD...\033[0m"
if ! kubectl get deployments -n argocd -l app.kubernetes.io/name=argocd-server -o name &> /dev/null; then
    helm install argocd argo/argo-cd --namespace argocd
else
    echo -e "\033[0;32mArgoCD already installed, skipping installation.\033[0m"
fi

# Step 7: Wait for ArgoCD to be ready
echo -e "\033[0;33mWaiting for ArgoCD to be ready...\033[0m"
sleep 10
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Step 8: Get ArgoCD password
echo -e "\033[0;33mGetting ArgoCD admin password...\033[0m"
password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo -e "\033[0;32mArgoCD admin password: $password\033[0m"

# Step 9: Install bootstrap chart
echo -e "\033[0;33mInstalling bootstrap chart...\033[0m"

read -p "Enter your GitHub username (leave empty for public repository): " githubUsername
if [ -z "$githubUsername" ]; then
    # Public repository
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
else
    # Private repository
    read -s -p "Enter your GitHub personal access token: " githubToken
    echo ""
    
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd \
        --set repository.auth.username="$githubUsername" \
        --set repository.auth.password="$githubToken"
fi

# Step 10: Start port-forward for ArgoCD
echo -e "\033[0;33mStarting port-forward for ArgoCD...\033[0m"
echo -e "\033[0;32mAccess ArgoCD at https://localhost:8080\033[0m"
echo -e "\033[0;32mUsername: admin\033[0m"
echo -e "\033[0;32mPassword: $password\033[0m"

# Start port-forward in the background
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

echo -e "\033[0;36mBootstrap complete!\033[0m"
