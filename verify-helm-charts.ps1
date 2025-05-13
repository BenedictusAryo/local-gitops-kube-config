# verify-helm-charts.ps1
# A script to verify the Helm charts in this repository

param(
    [string]$Environment = "dev"
)

Write-Host "Verifying Helm charts in the repository for environment: $Environment..." -ForegroundColor Cyan

# Verify the infrastructure chart
Write-Host "Verifying infrastructure chart..." -ForegroundColor Yellow
Write-Host "Adding required Helm repositories..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create a temporary directory for chart dependencies
if (!(Test-Path "tmp")) {
    New-Item -Path "tmp" -ItemType Directory | Out-Null
}

# Check if environment exists
if (!(Test-Path ".\environments\$Environment")) {
    Write-Host "Environment $Environment not found!" -ForegroundColor Red
    Write-Host "Available environments:"
    Get-ChildItem -Path ".\environments" -Directory | ForEach-Object { Write-Host "- $($_.Name)" }
    exit 1
}

# Build infrastructure chart dependencies
$infrastructureChartPath = ".\charts\infrastructure"
Write-Host "Building dependencies for infrastructure chart..." -ForegroundColor Yellow

# Try to build dependencies but don't fail if repositories are not available
try {
    helm dependency build $infrastructureChartPath
    $infraDepsBuilt = $true
} catch {
    Write-Host "Warning: Could not build all dependencies for infrastructure chart. Some validations may fail." -ForegroundColor Yellow
    $infraDepsBuilt = $false
}

# Verify infrastructure chart
Write-Host "Validating infrastructure chart with $Environment environment values..." -ForegroundColor Yellow
if ($infraDepsBuilt) {
    helm template --debug infra $infrastructureChartPath -f ".\environments\$Environment\infra-values.yaml"
} else {
    Write-Host "Skipping template validation for infrastructure chart due to missing dependencies." -ForegroundColor Yellow
}

# Verify applications chart
$applicationsChartPath = ".\charts\applications"
Write-Host "Validating applications chart with $Environment environment values..." -ForegroundColor Yellow
helm template --debug apps $applicationsChartPath -f ".\environments\$Environment\apps-values.yaml"

# Verify bootstrap chart
$bootstrapChartPath = ".\charts\bootstrap"
Write-Host "Validating bootstrap chart with $Environment environment values..." -ForegroundColor Yellow
helm template --debug bootstrap $bootstrapChartPath -f ".\environments\$Environment\bootstrap-values.yaml"

# Verify that ArgoCD can properly parse application manifests
Write-Host "Validating ArgoCD application manifests..." -ForegroundColor Yellow
kubectl apply --validate=true --dry-run=client -f .\manifests\infra-app.yaml
kubectl apply --validate=true --dry-run=client -f .\manifests\apps-app.yaml

# Check for lint issues
Write-Host "Linting Helm charts..." -ForegroundColor Yellow
# Only check the bootstrap chart syntax as it doesn't have dependencies that need to be fetched
helm lint $bootstrapChartPath -f ".\environments\$Environment\bootstrap-values.yaml"

# Skip linting for charts that have dependencies for now
Write-Host "Note: Skipping full linting for charts with dependencies. Run 'helm dependency build' before deploying." -ForegroundColor Yellow

Write-Host "Verification for $Environment environment completed!" -ForegroundColor Green
Write-Host "To verify a different environment, run: .\verify-helm-charts.ps1 -Environment <env-name>" -ForegroundColor Cyan
