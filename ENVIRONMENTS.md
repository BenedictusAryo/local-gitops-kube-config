# Multi-Environment Deployment Guide

This guide explains how to deploy the GitOps configuration to different environments.

## Available Environments

The repository supports the following environments:

- **dev**: Local development environment (default)
- **prod**: Production-like environment with high availability settings

## Environment-Specific Configuration

Each environment has its own configuration files in the `environments/<env>` directory:

- `bootstrap-values.yaml`: Values for the bootstrap Helm chart
- `infra-values.yaml`: Values for infrastructure components
- `apps-values.yaml`: Values for application components

## Deploying to Different Environments

### Development Environment (Default)

```powershell
# Bootstrap ArgoCD with development values
helm install bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
```

### Production Environment

```powershell
# Bootstrap ArgoCD with production values
helm install bootstrap ./charts/bootstrap -f ./environments/prod/bootstrap-values.yaml --namespace argocd
```

## Switching Environments

To switch between environments, update the ArgoCD applications to use different value files:

```powershell
# Switch to production
helm upgrade bootstrap ./charts/bootstrap -f ./environments/prod/bootstrap-values.yaml --namespace argocd

# Switch back to development
helm upgrade bootstrap ./charts/bootstrap -f ./environments/dev/bootstrap-values.yaml --namespace argocd
```

## Creating Additional Environments

To create a new environment (e.g., staging):

1. Create a new directory in the `environments` folder:
   ```bash
   mkdir -p environments/staging
   ```

2. Copy and modify the values files from an existing environment:
   ```bash
   cp environments/dev/*.yaml environments/staging/
   ```

3. Deploy using the new environment's values:
   ```bash
   helm install bootstrap ./charts/bootstrap -f ./environments/staging/bootstrap-values.yaml --namespace argocd
   ```

## Environment Promotion

To promote configurations from one environment to another:

1. Test changes in the development environment
2. Update the relevant values files in the target environment
3. Commit and push the changes
4. ArgoCD will automatically apply the changes to the target environment

## Environment-Specific Branches (Alternative Approach)

For more complex scenarios, you can use Git branches to manage different environments:

```bash
# Create an environment-specific branch
git checkout -b env/production

# Apply changes specific to that environment
git commit -am "Update production configuration"
git push origin env/production
```

Then configure ArgoCD to watch the appropriate branch for each environment.
