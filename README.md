# Local GitOps CI/CD with Kind, ArgoCD, and Helm

Develop and experience a local GitOps workflow for Kubernetes applications using Docker, Kind, Kubernetes, ArgoCD, Helm, and GitHub.

> **New to this project?** Check out the [QuickStart Guide](./QUICKSTART.md) for a fast setup!

## Purpose

This project demonstrates how to establish a GitOps-driven development environment on your local workstation. By leveraging tools like Kind for local Kubernetes clusters, Helm for packaging applications, and ArgoCD for continuous delivery from Git, you can simulate and learn production-grade CI/CD practices. This setup allows for declarative configuration management, automated deployments, and a clear audit trail of all changes made to your applications and infrastructure, all managed through Git repositories.

## Architecture

The following diagram illustrates the GitOps workflow established in this project:

```mermaid
graph TD
    %% Define styles with better colors and contrast
    classDef developer fill:#6C8EBF,stroke:#5A7AA8,color:white,stroke-width:2px
    classDef github fill:#24292E,stroke:#1B1F23,color:white,stroke-width:2px
    classDef argocd fill:#EF7B4D,stroke:#D35F33,color:white,stroke-width:2px
    classDef helm fill:#0F1689,stroke:#0A0F5A,color:white,stroke-width:2px
    classDef kubernetes fill:#326CE5,stroke:#2156C8,color:white,stroke-width:2px
    classDef user fill:#2DC26B,stroke:#25A257,color:white,stroke-width:2px
    classDef appDef fill:#8E44AD,stroke:#73359A,color:white,stroke-width:2px

    A[Developer] -->|Pushes App Code & Helm Chart| G_APP[GitHub: fastapi-app<br>Private Repo]
    A -->|Pushes Config Manifests| G_CONF[GitHub: local-gitops-kube-config<br>Private Repo]

    subgraph "ArgoCD Watches & Deploys"
        ARGO[ArgoCD - Running in Kind Cluster] -->|Watches| G_CONF
        G_CONF -->|Defines Argo App for Infra| APP_NGINX_DEF[Nginx App Definition]
        G_CONF -->|Defines Argo App for Infra| APP_PG_DEF[PostgreSQL App Definition]
        G_CONF -->|Defines Argo App for App| APP_FASTAPI_DEF[FastAPI App Definition]

        APP_NGINX_DEF -->|References Helm Chart| HC_NGINX[Public Helm Chart - Nginx]
        APP_PG_DEF -->|References Helm Chart| HC_PG[Public Helm Chart - PostgreSQL]
        APP_FASTAPI_DEF -->|References App Helm Chart| G_APP

        ARGO -->|Deploys/Manages| K_NGINX[Nginx Ingress]
        ARGO -->|Deploys/Manages| K_PG[PostgreSQL]
        ARGO -->|Deploys/Manages| K_FASTAPI[FastAPI App]
    end

    subgraph "Local Kubernetes Cluster (Kind)"
        KIND[Kind Cluster]
        K_NGINX -->|Routes Traffic| K_FASTAPI
        K_FASTAPI -->|Connects to| K_PG
        KIND -.-> ARGO
    end

    USER[User/Client] -->|Accesses<br>fastapi.localhost:8080| K_NGINX

    %% Apply the defined styles
    class A developer
    class G_APP,G_CONF github
    class ARGO argocd
    class HC_NGINX,HC_PG helm
    class KIND,K_NGINX,K_PG,K_FASTAPI kubernetes
    class USER user
    class APP_NGINX_DEF,APP_PG_DEF,APP_FASTAPI_DEF appDef
```

## Tools & Explanation
This project utilizes the following tools to achieve a local GitOps workflow:

### Docker:

* **_Explanation:_** A platform for developing, shipping, and running applications in containers.
* **_Role:_** Used to containerize the FastAPI application. Docker Desktop also provides the underlying container runtime for Kind on macOS and Windows.

### Kind (Kubernetes in Docker):

* **_Explanation:_** A tool for running local Kubernetes clusters using Docker container "nodes."
* **_Role:_** Provides the local Kubernetes environment where all applications (ArgoCD, Nginx, PostgreSQL, FastAPI app) are deployed and managed. It allows for quick creation and deletion of multi-node Kubernetes clusters for development and testing.

### Kubernetes (K8s):

* **_Explanation:_** An open-source system for automating deployment, scaling, and management of containerized applications.
* **_Role:_** The orchestration platform that runs our applications. Kind creates a conformant Kubernetes cluster.

### Helm:

* **_Explanation:_** The package manager for Kubernetes. Helm Charts help you define, install, and upgrade even the most complex Kubernetes applications. [https://dev.to/kitarp29/hatching-a-helm-chart-l52]
* **_Role:_** Used to package the FastAPI application and to deploy infrastructure components like Nginx Ingress and PostgreSQL. ArgoCD leverages Helm charts for deploying these applications.

### ArgoCD:

* **_Explanation:_** A declarative, GitOps continuous delivery tool for Kubernetes.
* **_Role:_** The core of our GitOps workflow. ArgoCD monitors the local-gitops-kube-config repository for changes to application definitions (which point to Helm charts or other Kubernetes manifests). When changes are detected, ArgoCD automatically syncs the desired state from Git to the Kind cluster, ensuring the cluster's state matches the configuration in Git.

### Git:

* **_Explanation:_** A distributed version control system.
* **_Role:_** Used to manage the source code for the FastAPI application (fastapi-app repository) and the Kubernetes/ArgoCD configurations (local-gitops-kube-config repository). Git serves as the single source of truth for our applications and their desired state.

### GitHub:

* **_Explanation:_** A platform for hosting Git repositories.
* **_Role:_** Hosts the private Git repositories (fastapi-app and local-gitops-kube-config) that ArgoCD monitors. Changes pushed to these repositories trigger the GitOps workflow.

## Setting Up the Local Kubernetes Cluster using Kind
### Prerequisites & CLI Installations

1. Install Docker Desktop: [Download Docker Desktop](https://www.docker.com/products/docker-desktop). Docker Desktop includes kubectl.
2. Install CLI tools:
   - macOS (using Homebrew):
     ```bash
     brew install kind helm argocd base64
     ```
   - Windows (using Scoop):
     ```bash
     scoop install kind helm argocd base64
     ```

1. **`local-cluster-deployment.yaml`:**
Find this file in the root of this local-gitops-kube-config repository:
```yaml
# local-cluster-deployment.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: local-gitops-cluster # Define the cluster name here
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080 # Host port for HTTP ingress, access at http://localhost:8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443 # Host port for HTTPS ingress, access at https://localhost:8443
    protocol: TCP
- role: worker
- role: worker
```

2. **Create the Cluster:**
Navigate to the directory containing `local-cluster-deployment.yaml` and run:
```bash
kind create cluster --config=local-cluster-deployment.yaml
```
If you didn't include name in the YAML, or want to override it:
```bash
kind create cluster --config=local-cluster-deployment.yaml --name local-gitops-cluster
```
Verify the cluster:
```bash
kubectl cluster-info --context kind-local-gitops-cluster
```

3. **Install ArgoCD** manually and port-forward for local access:
*  **Create a Dedicated Namespace**
```bash
kubectl create namespace argocd
```
This creates a Kubernetes namespace called "argocd" where all ArgoCD components will be deployed, keeping them isolated from other applications.

* **Bootstrap ArgoCD with Helm**
Manually install Argo CD into your cluster first. 
```bash
# Add the ArgoCD Helm repo and update
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD via Helm
helm install argocd argo/argo-cd --namespace argocd
```

* **Get initial ArgoCD Password**
The default password for the admin user is auto-generated. Get it:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# or
argocd admin initial-password -n argocd
```

* **Port Forward Access**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then navigate to https://127.0.0.1:8080/ to change the password.

* **Use ArgoCD CLI**
```bash
# Log in to the local ArgoCD server
argocd login 127.0.0.1:8080 --username admin --password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" --insecure

# (Optional) If you have multiple ArgoCD API contexts, set the default
argocd context localhost:8080

# Ensure kubectl is pointing at your Kind cluster
kubectl config use-context kind-local-gitops-cluster
``` 

* **(Optional) change ArgoCD admin password and remove initial secret**
```bash
# Change admin password (interactive)
argocd account update-password

# After successfully changing the password, delete the initial secret
kubectl -n argocd delete secret argocd-initial-admin-secret
```

## Connecting ArgoCD to GitHub Repository

After installing ArgoCD and gaining access to the UI, you need to connect ArgoCD to your GitHub repository to enable the GitOps workflow. Here's how to do it:

### 1. Login to ArgoCD CLI (Optional, should be done in previous step)

Install the ArgoCD CLI and login:

```bash
# Login to ArgoCD using the CLI
argocd login localhost:8080 --username admin --password <your-password> --insecure
```

### 2. Add Repository to ArgoCD

You can add your repository using either the CLI or the UI:

#### Using ArgoCD CLI:

```bash
# For a public repository
argocd repo add https://github.com/BenedictusAryo/local-gitops-kube-config.git

# For a private repository with username/password
argocd repo add https://github.com/BenedictusAryo/local-gitops-kube-config.git \
  --username <github-username> \
  --password <github-personal-access-token>

# For a private repository with SSH
argocd repo add git@github.com:BenedictusAryo/local-gitops-kube-config.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

#### Using ArgoCD UI:

1. Open the ArgoCD UI (https://localhost:8080)
2. Login with admin credentials
3. Navigate to "Settings" → "Repositories" → "Connect Repo"
4. Fill in the repository details:
   - For public repos: Just the HTTPS URL
   - For private repos: Add authentication details
5. Click "Connect" to add the repository

### 3. Create the Initial ArgoCD Applications

Now you need to create the initial ArgoCD Applications that will deploy your infrastructure and applications. We'll use a bootstrap Helm chart to set this up:

```bash
# Install the bootstrap chart to create ArgoCD applications
helm install bootstrap ./charts/bootstrap \
  -f ./environments/dev/bootstrap-values.yaml \
  --namespace argocd

# For private repositories, add your credentials
helm install bootstrap ./charts/bootstrap \
  -f ./environments/dev/bootstrap-values.yaml \
  --namespace argocd \
  --set repository.auth.username=<github-username> \
  --set repository.auth.password=<github-personal-access-token>
```

This bootstrap chart will create ArgoCD applications that define the connection between ArgoCD and specific paths in your repository.

### 4. Verify the Connection

Verify that ArgoCD has successfully connected to your repository:

```bash
# Check repositories
argocd repo list

# Check applications
argocd app list
```

In the ArgoCD UI, you should now see your applications and their sync status.

### 5. Working with Private Repositories

If you're using private repositories, you have several authentication options:

1. **Personal Access Token (PAT)**: Create a GitHub PAT with `repo` scope
2. **Deploy Keys**: Add a repository-specific SSH key
3. **GitHub App**: For more granular permissions

For local development with a private repository, using a PAT is typically the simplest approach:

#### Option 1: Using Helm values for authentication

When installing the bootstrap chart, provide your GitHub credentials:

```bash
# Install bootstrap chart with repository credentials
helm install bootstrap ./charts/bootstrap \
  -f ./environments/dev/bootstrap-values.yaml \
  --namespace argocd \
  --set repository.auth.username=<github-username> \
  --set repository.auth.password=<github-personal-access-token>
```

#### Option 2: Manually creating a secret

Alternatively, you can manually create a secret:

```bash
# Create a Kubernetes secret for GitHub credentials
kubectl create secret generic repo-github-benedictusaryo-local-gitops-kube-config \
  --namespace argocd \
  --from-literal=type=git \
  --from-literal=url=https://github.com/BenedictusAryo/local-gitops-kube-config.git \
  --from-literal=username=<github-username> \
  --from-literal=password=<github-personal-access-token> \
  --label=argocd.argoproj.io/secret-type=repository
```

#### Option 3: Using SSH

For SSH authentication, update your bootstrap values file:

```yaml
repository:
  url: git@github.com:BenedictusAryo/local-gitops-kube-config.git
  auth:
    sshPrivateKey: |-
      -----BEGIN OPENSSH PRIVATE KEY-----
      Your private key content goes here
      -----END OPENSSH PRIVATE KEY-----
```

Once the repository connection is established, ArgoCD will continuously monitor your Git repository for changes and automatically apply them to your Kubernetes cluster according to the defined applications.

---

## Repository Structure
This repository is structured to manage the deployment of various applications into the Kubernetes cluster via ArgoCD:

```
local-gitops-kube-config/               # This repository
├── charts/                             # Main directory for Helm charts
│   ├── bootstrap/                      # Bootstrap chart for ArgoCD application setup
│   │   ├── Chart.yaml                  # Bootstrap chart definition
│   │   ├── values.yaml                 # Default values for bootstrap
│   │   └── templates/                  # Bootstrap templates
│   │       ├── apps-app.yaml           # Template for applications ArgoCD app
│   │       ├── infra-app.yaml          # Template for infrastructure ArgoCD app
│   │       └── repository-secret.yaml  # Template for Git repository secret
│   ├── infrastructure/                 # Parent chart for all infrastructure components
│   │   ├── Chart.yaml                  # Main chart definition
│   │   ├── values.yaml                 # Default values for infrastructure
│   │   └── charts/                     # Subcharts for infrastructure components
│   │       ├── argocd/                 # ArgoCD subchart (for self-management after initial setup)
│   │       ├── nginx-ingress/          # Nginx Ingress subchart
│   │       └── postgresql/             # PostgreSQL subchart
│   └── applications/                   # Parent chart for all applications
│       ├── Chart.yaml                  # Main chart definition
│       ├── values.yaml                 # Default values for applications
│       └── charts/                     # Subcharts for applications
│           └── fastapi-app/            # FastAPI application subchart
├── manifests/                          # Legacy ArgoCD Application manifests (kept for reference)
│   ├── infra-app.yaml                  # ArgoCD Application for infrastructure
│   └── apps-app.yaml                   # ArgoCD Application for applications
└── environments/                       # Environment-specific overrides
    └── dev/                            # Development environment
        ├── bootstrap-values.yaml       # Bootstrap values for dev
        ├── infra-values.yaml           # Infra values override for dev
        └── apps-values.yaml            # App values override for dev
```

### Helm Chart and Subchart Structure

This repository uses Helm's parent-child chart relationship (umbrella charts) to organize deployments:

- **Parent Charts**: The `infrastructure` and `applications` directories contain parent charts that serve as logical groupings for related components.

- **Subcharts**: Each parent chart contains a `charts` directory with subcharts for individual components. These can be either:
  - Custom charts developed for this project (like `fastapi-app`)
  - Dependencies on public charts (defined in the parent chart's `Chart.yaml` and stored in the `charts` directory)

- **Values Management**: 
  - Each chart has its default `values.yaml`
  - Environment-specific values are stored in the `environments` directory
  - Values cascade from parent charts to subcharts, allowing for centralized configuration

This structure supports Helm's reusability while maintaining clear separation between components.

### Separation Between Infrastructure and Applications

This repository maintains a clear distinction between infrastructure and application components:

- **Infrastructure Components** (`charts/infrastructure/`):
  - These are foundational services necessary for the platform to function
  - Typically requires admin/elevated privileges to deploy
  - Changes less frequently than applications
  - Includes components like ArgoCD (for self-management), Nginx Ingress, and databases

- **Applications** (`charts/applications/`):
  - Business logic and services that provide direct value
  - Can be deployed by development teams with appropriate permissions
  - Change more frequently as business needs evolve
  - Includes components like the FastAPI application

This separation provides several benefits:
- Clear ownership boundaries between platform and application teams
- Different deployment cadences and approval processes
- Ability to version and roll back infrastructure separately from applications
- Better alignment with organizational responsibilities

## Multiple Environments

This repository supports multiple deployment environments:

- **dev**: Local development environment (default)
- **prod**: Production-like environment with high availability settings

For detailed information on deploying to different environments, see the [Environments Guide](./ENVIRONMENTS.md).

## CI/CD Workflow

The GitOps workflow implemented in this project follows these steps:

1. **Initial Setup**:
   - Create a Kind cluster using the configuration provided
   - Manually deploy ArgoCD to bootstrap the GitOps process
   - Install the bootstrap Helm chart to create ArgoCD applications
   - Alternatively, use the `bootstrap-local-gitops.ps1` script to automate the entire setup

2. **Infrastructure Deployment**:
   - ArgoCD pulls the infrastructure chart and its subcharts 
   - Creates or updates infrastructure components (including ArgoCD itself)
   - Infrastructure becomes self-managed through GitOps

3. **Application Deployment**:
   - Update application code in the FastAPI repository
   - Update application Helm chart as needed
   - ArgoCD detects changes and automatically deploys updates

4. **Making Changes**:
   - To modify infrastructure: Update values in `environments/dev/infra-values.yaml`
   - To modify applications: Update values in `environments/dev/apps-values.yaml`
   - Commit and push changes to trigger automatic deployment

5. **Monitoring Deployments**:
   ```bash
   # View ArgoCD applications status
   kubectl get applications -n argocd
   
   # View sync status and health of all applications
   argocd app list
   
   # Get detailed information about a specific application
   argocd app get infrastructure
   ```