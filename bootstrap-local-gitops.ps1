# bootstrap-local-gitops.ps1
# A script to bootstrap the local GitOps environment

Write-Host "Bootstrapping local GitOps environment..." -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$prerequisites = @("docker", "kind", "kubectl", "helm")
$missing = @()

foreach ($tool in $prerequisites) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Missing required tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install these tools before continuing." -ForegroundColor Red
    exit 1
}

# Step 1.5: Prepare charts
Write-Host "Preparing Helm charts..." -ForegroundColor Yellow
& .\prepare-charts.ps1

# Step 2: Create Kind cluster if it doesn't exist
Write-Host "Creating Kind cluster..." -ForegroundColor Yellow
$clusterExists = kind get clusters | Select-String -Pattern "local-gitops-cluster" -Quiet
if (-not $clusterExists) {
    kind create cluster --config=local-cluster-deployment.yaml
} else {
    Write-Host "Cluster 'local-gitops-cluster' already exists, skipping creation." -ForegroundColor Green
}

# Step 3: Set kubectl context
kubectl config use-context kind-local-gitops-cluster

# Step 4: Create ArgoCD namespace
Write-Host "Creating ArgoCD namespace..." -ForegroundColor Yellow
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Step 5: Add Helm repositories
Write-Host "Adding Helm repositories..." -ForegroundColor Yellow
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Step 6: Install ArgoCD
Write-Host "Installing ArgoCD..." -ForegroundColor Yellow
$argocdExists = kubectl get deployments -n argocd -l app.kubernetes.io/name=argocd-server -o name
if (-not $argocdExists) {
    helm install argocd argo/argo-cd --namespace argocd
} else {
    Write-Host "ArgoCD already installed, skipping installation." -ForegroundColor Green
}

# Step 7: Wait for ArgoCD to be ready
Write-Host "Waiting for ArgoCD to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Step 8: Get ArgoCD password
Write-Host "Getting ArgoCD admin password..." -ForegroundColor Yellow
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "ArgoCD admin password: $password" -ForegroundColor Green

# Step 9: Install bootstrap chart
Write-Host "Installing bootstrap chart..." -ForegroundColor Yellow

$githubUsername = Read-Host "Enter your GitHub username (leave empty for public repository)"
if ([string]::IsNullOrWhiteSpace($githubUsername)) {
    # Public repository
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
} else {
    # Private repository
    $githubToken = Read-Host "Enter your GitHub personal access token" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken)
    $tokenPlaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd `
        --set repository.auth.username=$githubUsername `
        --set repository.auth.password=$tokenPlaintext
}

# Step 10: Start port-forward for ArgoCD
Write-Host "Starting port-forward for ArgoCD..." -ForegroundColor Yellow
Write-Host "Access ArgoCD at https://localhost:8080" -ForegroundColor Green
Write-Host "Username: admin" -ForegroundColor Green
Write-Host "Password: $password" -ForegroundColor Green

Start-Process powershell -ArgumentList "-Command", "kubectl port-forward svc/argocd-server -n argocd 8080:443"

Write-Host "Bootstrap complete!" -ForegroundColor Cyan
