# Quick Start Guide

This quick start guide will help you set up a local GitOps environment with Kind, Kubernetes, ArgoCD, and Helm.

## Prerequisites

Make sure you have the following tools installed:

- Docker Desktop
- kubectl
- kind
- helm
- ArgoCD CLI (optional, but recommended)

## Option 1: Automated Setup (Recommended)

The quickest way to get started is to use the automated setup script:

```powershell
# First, prepare the Helm charts
.\prepare-charts.ps1

# Then run the bootstrap script
.\bootstrap-local-gitops.ps1
```

This script will:
1. Check for prerequisites
2. Create a Kind cluster
3. Install ArgoCD
4. Set up the bootstrap Helm chart
5. Start port-forwarding for ArgoCD UI access

## Option 2: Manual Setup

If you prefer to set up the environment manually, follow these steps:

### 1. Create the Kind Cluster

```powershell
# Create the Kind cluster
kind create cluster --config=local-cluster-deployment.yaml
```

### 2. Install ArgoCD

```powershell
# Create namespace for ArgoCD
kubectl create namespace argocd

# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd --namespace argocd
```

### 3. Access ArgoCD UI

```powershell
# Get the initial admin password
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
Write-Host "ArgoCD admin password: $password"

# Start port-forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access the ArgoCD UI at https://localhost:8080

### 4. Bootstrap ArgoCD Applications

```powershell
# For public repository
helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd

# For private repository
helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd `
  --set repository.auth.username=<github-username> `
  --set repository.auth.password=<github-personal-access-token>
```

## Verifying Your Setup

```powershell
# Check if ArgoCD applications are created
kubectl get applications -n argocd

# Verify the Helm charts
.\verify-helm-charts.ps1
```

## Preparing Your Charts

Before running the bootstrap script or if you encounter issues with chart dependencies, run the prepare-charts script:

```powershell
# Prepare charts for development
.\prepare-charts.ps1
```

This script will:
1. Create necessary directory structures for chart dependencies
2. Add required Helm repositories
3. Build chart dependencies

This step is important to ensure that your Helm charts can be properly validated and deployed.

## Next Steps

1. Explore the ArgoCD UI at https://localhost:8080
2. Make changes to the values files in the `environments/dev/` directory
3. Push changes to your Git repository
4. Watch ArgoCD automatically sync and deploy the changes

For more detailed information, refer to the main [README.md](./README.md) file.
