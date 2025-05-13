# Bash Scripts for Mac/Linux Users

This directory contains bash versions of the PowerShell scripts for Mac/Linux users who want to work with the GitOps setup.

## Making Scripts Executable

When using these scripts on Mac or Linux, you'll first need to make them executable:

```bash
chmod +x bootstrap-local-gitops.sh verify-helm-charts.sh update-gitops-config.sh prepare-charts.sh
```

## Available Scripts

1. **bootstrap-local-gitops.sh**
   - Creates a new Kind cluster with the specified configuration
   - Installs ArgoCD
   - Sets up the initial GitOps configuration

2. **verify-helm-charts.sh**
   - Validates all Helm charts in the repository
   - Usage: `./verify-helm-charts.sh [environment]`
   - Default environment is "dev" if not specified

3. **update-gitops-config.sh**
   - Updates the GitOps configuration in an existing environment
   - Automatically commits and pushes changes to Git
   - Options:
     - `--skip-push`: Skip pushing changes to Git

4. **prepare-charts.sh**
   - Prepares the charts directory structure
   - Sets up dependencies for Helm charts

## Usage Examples

### Initial Setup

```bash
# Make scripts executable
chmod +x *.sh

# Bootstrap the environment
./bootstrap-local-gitops.sh
```

### Update Configuration

```bash
# Update the GitOps configuration
./update-gitops-config.sh

# Update without pushing changes to Git
./update-gitops-config.sh --skip-push
```

### Verify Charts for Different Environments

```bash
# Verify dev environment (default)
./verify-helm-charts.sh

# Verify prod environment
./verify-helm-charts.sh prod
```

## Note for Windows Users

These bash scripts provide the same functionality as their PowerShell counterparts but are designed for Unix-based systems. If you're on Windows, please use the equivalent PowerShell scripts instead.
