# Applications Helm Chart

This chart deploys business applications to your Kubernetes cluster.

## Introduction

The applications chart is designed as a parent chart that includes multiple subcharts for various business applications.
It serves as a unified way to deploy and manage application components like:
- FastAPI application

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1+
- Infrastructure components installed (nginx-ingress, postgresql)

## Installing the Chart

This chart is typically installed via ArgoCD as part of a GitOps workflow:

```bash
# Manual installation for testing
helm dependency build
helm install applications . -f ../environments/dev/apps-values.yaml --namespace applications --create-namespace
```

## Components

### FastAPI Application

A sample FastAPI application is deployed as part of this chart.
Configuration is available in `values.yaml` under the `fastapi-app` key.

## Configuration

Refer to the `values.yaml` file for the default values and the various subcharts' documentation
for more detailed configuration options.
