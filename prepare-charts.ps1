# prepare-charts.ps1
# A script to prepare the charts directory structure for development

Write-Host "Preparing Helm charts for development..." -ForegroundColor Cyan

# Create necessary directories for infrastructure chart dependencies
$infraChartDirs = @(
    ".\charts\infrastructure\charts\ingress-nginx",
    ".\charts\infrastructure\charts\postgresql",
    ".\charts\infrastructure\charts\argo-cd"
)

foreach ($dir in $infraChartDirs) {
    if (!(Test-Path $dir)) {
        Write-Host "Creating directory: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        # Add a .gitkeep file to ensure the directory is tracked by git
        New-Item -Path "$dir\.gitkeep" -ItemType File -Force | Out-Null
    }
}

# Create necessary directories for application chart dependencies
$appChartDirs = @(
    ".\charts\applications\charts\fastapi-app"
)

foreach ($dir in $appChartDirs) {
    if (!(Test-Path $dir)) {
        Write-Host "Creating directory: $dir" -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        # Add a .gitkeep file to ensure the directory is tracked by git
        New-Item -Path "$dir\.gitkeep" -ItemType File -Force | Out-Null
    }
}

# Add Helm repositories
Write-Host "Adding required Helm repositories..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Build chart dependencies
Write-Host "Building chart dependencies..." -ForegroundColor Yellow
try {
    helm dependency build .\charts\infrastructure
    Write-Host "Infrastructure chart dependencies built successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to build infrastructure chart dependencies. You may need to install them manually." -ForegroundColor Yellow
}

try {
    helm dependency build .\charts\applications
    Write-Host "Applications chart dependencies built successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to build applications chart dependencies. You may need to install them manually." -ForegroundColor Yellow
}

Write-Host "Charts preparation completed!" -ForegroundColor Green
