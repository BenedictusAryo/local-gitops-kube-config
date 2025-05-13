# FastAPI App Helm Chart

A Helm chart to deploy a FastAPI application on Kubernetes.

## Introduction

This Helm chart deploys a FastAPI application along with its required resources:
- Deployment
- Service
- Ingress
- ConfigMap
- Secrets
- ServiceAccount
- HorizontalPodAutoscaler (optional)

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1+
- Ingress controller installed
- PostgreSQL database available

## Configuration

The following table lists the configurable parameters of the FastAPI chart and their default values.

### General Settings

| Parameter            | Description                       | Default              |
| -------------------- | --------------------------------- | -------------------- |
| `replicaCount`       | Number of replicas                | `2`                  |
| `image.repository`   | Docker image repository           | `ghcr.io/benedictusaryo/fastapi-app` |
| `image.tag`          | Docker image tag                  | `latest`             |
| `image.pullPolicy`   | Image pull policy                 | `Always`             |
| `nameOverride`       | Override chart name               | `""`                 |
| `fullnameOverride`   | Override full chart name          | `""`                 |

### Service Settings

| Parameter        | Description                       | Default       |
| ---------------- | --------------------------------- | ------------- |
| `service.type`   | Type of service                   | `ClusterIP`   |
| `service.port`   | Service port                      | `8000`        |

### Ingress Settings

| Parameter                    | Description                       | Default                      |
| ---------------------------- | --------------------------------- | ---------------------------- |
| `ingress.enabled`            | Enable ingress                    | `true`                       |
| `ingress.className`          | Ingress class name                | `nginx`                      |
| `ingress.hosts[0].host`      | Hostname                          | `fastapi.localhost`          |
| `ingress.hosts[0].paths[0].path` | Path                          | `/`                          |
| `ingress.hosts[0].paths[0].pathType` | Path type                 | `Prefix`                     |

### Resources Settings

| Parameter            | Description                       | Default              |
| -------------------- | --------------------------------- | -------------------- |
| `resources.limits.cpu`      | CPU limit                  | `500m`               |
| `resources.limits.memory`   | Memory limit               | `512Mi`              |
| `resources.requests.cpu`    | CPU request                | `100m`               |
| `resources.requests.memory` | Memory request             | `128Mi`              |

### Database Settings

| Parameter              | Description                       | Default                                   |
| ---------------------- | --------------------------------- | ----------------------------------------- |
| `postgresql.host`      | PostgreSQL host                   | `postgresql.infrastructure.svc.cluster.local` |
| `postgresql.port`      | PostgreSQL port                   | `5432`                                    |
| `postgresql.database`  | PostgreSQL database name          | `appdb`                                   |
| `postgresql.username`  | PostgreSQL username               | `appuser`                                 |
| `postgresql.password`  | PostgreSQL password               | `apppassword`                             |

### Autoscaling Settings

| Parameter                                  | Description                  | Default |
| ------------------------------------------ | ---------------------------- | ------- |
| `autoscaling.enabled`                      | Enable autoscaling           | `false` |
| `autoscaling.minReplicas`                  | Minimum replicas             | `2`     |
| `autoscaling.maxReplicas`                  | Maximum replicas             | `5`     |
| `autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilization | `80`    |
| `autoscaling.targetMemoryUtilizationPercentage` | Target Memory utilization | `80` |
