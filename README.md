# Go Monitoring App (Kubernetes Native)

A simple Go web server deployed on Kubernetes, configured for GitOps with ArgoCD, and monitored using Prometheus and Grafana.

## Architecture

This project is fully Cloud Native:
- **Go App**: Distributed as a Docker image and managed via K8s Deployment.
- **Monitoring**: Prometheus (metrics scraping) and Grafana (visualization) running as independent pods.
- **GitOps**: Managed by ArgoCD via the manifests in the `kubernetes/` directory.

## Usage (Kubernetes)

1. **Deployment via ArgoCD**:
   ArgoCD tracks the `kubernetes/` folder. Simply push changes to GitHub, and ArgoCD will sync the state.

2. **Manual Deployment**:
   ```bash
   kubectl apply -f kubernetes/
   ```

3. **Accessing Services**:
   - **Go App**: `http://localhost:30002` (via NodePort)
   - **Prometheus**: `http://localhost:30090` (via NodePort)
   - **Grafana**: `http://localhost:30000` (via NodePort)

   *Note: If using Minikube, run `minikube service [service-name]` to get the URL.*

## ArgoCD Configuration

- **ArgoCD Server**: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- **Initial Password**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
