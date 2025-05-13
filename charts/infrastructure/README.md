# Infrastructure Helm Chart

This chart deploys core infrastructure components for your Kubernetes cluster.

## Introduction

The infrastructure chart is designed as a parent chart that includes multiple subcharts for critical infrastructure components.
It serves as a unified way to deploy and manage infrastructure components like:
- Nginx Ingress Controller
- PostgreSQL database
- ArgoCD (for self-management)

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1+
- Kind cluster (for local development)

## Installing the Chart

This chart is typically installed via ArgoCD as part of a GitOps workflow:

```bash
# Manual installation for testing
helm dependency build
helm install infrastructure . -f ../environments/dev/infra-values.yaml --namespace infrastructure --create-namespace
```

## Components

### Ingress Nginx Controller

The NGINX Ingress Controller is deployed to provide ingress capabilities to the cluster.
Configuration is available in `values.yaml` under the `ingress-nginx` key.

### PostgreSQL

A PostgreSQL database is deployed to provide data storage for applications.
Configuration is available in `values.yaml` under the `postgresql` key.

### ArgoCD

ArgoCD is deployed for GitOps management of the cluster.
Configuration is available in `values.yaml` under the `argo-cd` key.

## Configuration

Refer to the `values.yaml` file for the default values and the various subcharts' documentation
for more detailed configuration options.
