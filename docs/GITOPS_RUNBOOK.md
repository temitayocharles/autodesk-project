# GitOps Runbook (Deploy → Verify → Cleanup)

This repo is designed to deploy into your local k3s cluster via ArgoCD using:
- Charts: [`temitayocharles/helm-charts`](https://github.com/temitayocharles/helm-charts)
- GitOps apps/values: [`temitayocharles/platform-gitops`](https://github.com/temitayocharles/platform-gitops)
- ConfigMaps: [`temitayocharles/configurations`](https://github.com/temitayocharles/configurations)
- Secrets boundaries: [`temitayocharles/vault-ops`](https://github.com/temitayocharles/vault-ops)

## Images (GHCR)
CI pushes:
- `ghcr.io/temitayocharles/autodesk-data-api-service:staging-<sha>`
- `ghcr.io/temitayocharles/autodesk-data-ingestion-service:staging-<sha>`
- `ghcr.io/temitayocharles/autodesk-data-processing-service:staging-<sha>`

## Vault Paths (KV v2)
- `kv/temitayo/staging/autodesk-project/data-api-service`
- `kv/temitayo/staging/autodesk-project/data-ingestion-service`
- `kv/temitayo/staging/autodesk-project/data-processing-service`

## Deploy (Create/Sync Argo Apps)

### 1) Ensure Argo can read the `configurations` repo
`configurations` is private. ArgoCD must have repository credentials configured.

Recommended approach:
- Add an ArgoCD `repo-creds` secret for GitHub that includes `temitayocharles/configurations`.

### 2) Apply the Argo Applications
Run inside the VM:
```bash
ssh ubuntu-vm
sudo -n k3s kubectl -n argocd apply -f https://raw.githubusercontent.com/temitayocharles/platform-gitops/main/applications/autodesk/autodesk-data-api-service.yaml
sudo -n k3s kubectl -n argocd apply -f https://raw.githubusercontent.com/temitayocharles/platform-gitops/main/applications/autodesk/autodesk-data-ingestion-service.yaml
sudo -n k3s kubectl -n argocd apply -f https://raw.githubusercontent.com/temitayocharles/platform-gitops/main/applications/autodesk/autodesk-data-processing-service.yaml
```

### 3) Verify
```bash
ssh ubuntu-vm
sudo -n k3s kubectl -n argocd get applications | grep autodesk
sudo -n k3s kubectl -n apps get pods
```

Optional HTTP checks from inside the VM:
```bash
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: autodesk-data-api.local' http://127.0.0.1/
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: autodesk-data-ingestion.local' http://127.0.0.1/
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: autodesk-data-processing.local' http://127.0.0.1/
```

## Cleanup (Resource Conservation)
When you’re done verifying, delete the apps:
```bash
ssh ubuntu-vm
sudo -n k3s kubectl -n argocd delete application autodesk-data-api-service --wait=true
sudo -n k3s kubectl -n argocd delete application autodesk-data-ingestion-service --wait=true
sudo -n k3s kubectl -n argocd delete application autodesk-data-processing-service --wait=true
```

Confirm `apps` namespace is clean:
```bash
sudo -n k3s kubectl -n apps get all
sudo -n k3s kubectl -n apps get ingress
```

