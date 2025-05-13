# ArgoCD Application Manifests

These manifest files are kept for reference purposes only. The actual ArgoCD applications are now created using the bootstrap Helm chart located in `../charts/bootstrap/`.

## How to Use

Instead of directly applying these manifests with `kubectl apply -f`, use the bootstrap Helm chart:

```bash
helm install bootstrap ../charts/bootstrap -f ../environments/dev/bootstrap-values.yaml --namespace argocd
```

This provides better templating, value substitutions, and easier management of the ArgoCD applications.
