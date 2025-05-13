# ArgoCD Bootstrap Helm Chart

This chart is used to bootstrap ArgoCD applications for GitOps management.

## Introduction

The bootstrap chart creates ArgoCD Application resources that point to Helm charts in your Git repository.
It serves as the initial starting point for your GitOps workflow.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1+
- ArgoCD installed in your cluster
- Git repository containing your Helm charts

## Installing the Chart

To install the chart with the release name `bootstrap`:

```bash
# For public repositories
helm install bootstrap . -f ../environments/dev/bootstrap-values.yaml --namespace argocd

# For private repositories with username/password
helm install bootstrap . -f ../environments/dev/bootstrap-values.yaml --namespace argocd \
  --set repository.auth.username=<github-username> \
  --set repository.auth.password=<github-personal-access-token>

# For private repositories with SSH
helm install bootstrap . -f ../environments/dev/bootstrap-values.yaml --namespace argocd \
  --set repository.auth.sshPrivateKey="$(cat ~/.ssh/id_rsa | base64)"
```

## Parameters

### Repository Configuration

| Name                      | Description                                   | Value                                             |
| ------------------------- | --------------------------------------------- | ------------------------------------------------- |
| `repository.url`          | Git repository URL                            | `https://github.com/example/repo.git`             |
| `repository.auth.username`| Git repository username                       | `""`                                              |
| `repository.auth.password`| Git repository password or token              | `""`                                              |
| `repository.auth.sshPrivateKey`| Git repository SSH private key (base64 encoded) | `""`                                      |

### Application Configuration

| Name                              | Description                                       | Value            |
| --------------------------------- | ------------------------------------------------- | ---------------- |
| `applications.infrastructure.enabled` | Enable infrastructure application             | `true`           |
| `applications.infrastructure.name`    | Name of the infrastructure application        | `infrastructure` |
| `applications.infrastructure.namespace`| Namespace for infrastructure components      | `infrastructure` |
| `applications.infrastructure.path`    | Path to infrastructure chart in repository    | `charts/infrastructure` |
| `applications.infrastructure.valueFiles`| Value files for infrastructure application  | `["../../environments/dev/infra-values.yaml"]` |
| `applications.applications.enabled`   | Enable applications application               | `true`           |
| `applications.applications.name`      | Name of the applications application          | `applications`   |
| `applications.applications.namespace` | Namespace for application components          | `applications`   |
| `applications.applications.path`      | Path to applications chart in repository      | `charts/applications` |
| `applications.applications.valueFiles`| Value files for applications application      | `["../../environments/dev/apps-values.yaml"]` |
