# Go Monitoring App

A simple Go web server dockerized with Docker Compose, including Prometheus and Grafana for monitoring.

## Usage

1. Ensure Docker and Docker Compose are installed.

2. Run the application:
   ```bash
   docker-compose up --build
   ```
   kubectl port-forward svc/argocd-server -n argocd 8080:443   

3. Access the services:
   - App: http://localhost:3002
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (username: admin, password: admin)
   - ArgoCD: http://localhost:8080 (username: admin, password: [PASSWORD])
   - ArgoCD Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

## Troubleshooting

- If port 3002 is in use, change the port mapping in docker-compose.yml.
- Ensure Docker daemon is running.
