# update-gitops-config.ps1
# A script to update the GitOps configuration in an existing environment

param(
    [switch]$SkipPush = $false
)

Write-Host "Updating GitOps configuration..." -ForegroundColor Cyan

# Step 1: Check if the cluster exists
Write-Host "Checking Kind cluster..." -ForegroundColor Yellow
$clusterExists = kind get clusters | Select-String -Pattern "local-gitops-cluster" -Quiet
if (-not $clusterExists) {
    Write-Host "Cluster 'local-gitops-cluster' does not exist. Please run bootstrap-local-gitops.ps1 first." -ForegroundColor Red
    exit 1
}

# Step 2: Set kubectl context
kubectl config use-context kind-local-gitops-cluster

# Step 3: Check if ArgoCD is running
$argoRunning = kubectl get deployments -n argocd -l app.kubernetes.io/name=argocd-server -o name
if (-not $argoRunning) {
    Write-Host "ArgoCD is not running. Please run bootstrap-local-gitops.ps1 first." -ForegroundColor Red
    exit 1
}

# Step 4: Check bootstrap chart
$bootstrapExists = kubectl get deployments -n argocd -l app.kubernetes.io/instance=bootstrap -o name
if (-not $bootstrapExists) {
    Write-Host "Bootstrap chart is not installed. Installing now..." -ForegroundColor Yellow
    helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
} else {
    Write-Host "Upgrading bootstrap chart..." -ForegroundColor Yellow
    helm upgrade bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
}

# Step 5: Verify Helm charts
Write-Host "Verifying Helm charts..." -ForegroundColor Yellow
./verify-helm-charts.ps1

if (-not $SkipPush) {
    # Step 6: Commit and push changes (if git is available)
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Committing and pushing changes..." -ForegroundColor Yellow
        
        # Check if there are changes to commit
        $status = git status --porcelain
        if ($status) {
            $commitMessage = Read-Host "Enter commit message"
            if ([string]::IsNullOrWhiteSpace($commitMessage)) {
                $commitMessage = "Update GitOps configuration"
            }
            
            git add .
            git commit -m $commitMessage
            git push
            
            Write-Host "Changes pushed to repository. ArgoCD will automatically sync." -ForegroundColor Green
        } else {
            Write-Host "No changes to commit." -ForegroundColor Green
        }
    } else {
        Write-Host "Git command not found. Skipping commit and push." -ForegroundColor Yellow
    }
}

# Step 7: Force sync applications if needed
$forceSyncApps = Read-Host "Do you want to force sync ArgoCD applications? (y/N)"
if ($forceSyncApps -eq "y" -or $forceSyncApps -eq "Y") {
    # Check if ArgoCD CLI is available
    if (Get-Command argocd -ErrorAction SilentlyContinue) {
        # Get argocd password
        $password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
        if ($password) {
            $password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
            
            # Login to ArgoCD
            argocd login localhost:8080 --username admin --password $password --insecure
            
            # Force sync apps
            argocd app sync infrastructure --force
            argocd app sync applications --force
            
            Write-Host "Applications synced successfully." -ForegroundColor Green
        } else {
            Write-Host "Could not get ArgoCD password. Please sync applications manually through the UI." -ForegroundColor Yellow
        }
    } else {
        Write-Host "ArgoCD CLI not found. Please sync applications through the ArgoCD UI." -ForegroundColor Yellow
        Write-Host "Access ArgoCD UI at https://localhost:8080" -ForegroundColor Green
    }
}

Write-Host "Update complete!" -ForegroundColor Cyan
Write-Host "You can access the ArgoCD UI at https://localhost:8080" -ForegroundColor Green
