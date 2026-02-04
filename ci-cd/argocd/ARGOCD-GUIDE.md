# ArgoCD GitOps Setup Guide

## What is ArgoCD?

ArgoCD is a **declarative, GitOps continuous delivery tool** for Kubernetes. 

**GitOps Principles:**
- Git is the single source of truth
- Automated deployment from Git
- Kubernetes reconciles to match Git state
- Audit trail via Git history

## Why ArgoCD?

### Traditional CD (Jenkins):
```
Code → Jenkins → Build → Test → Deploy → K8s
         ↓
    Single point of failure
    Push-based (Jenkins pushes to K8s)
```

### GitOps CD (ArgoCD):
```
Code → Git → ArgoCD watches Git → K8s reconciles
              ↓
         Always in sync
         Pull-based (K8s pulls from Git)
```

**Benefits:**
- ✅ Automated sync (cluster matches Git)
- ✅ Self-healing (fixes drift automatically)
- ✅ Rollback via Git revert
- ✅ Multi-cluster management
- ✅ Beautiful UI
- ✅ Security (no cluster credentials in CI)

---

## Installation (Local Kubernetes)

### 1. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment --all -n argocd
```

### 2. Access ArgoCD UI

```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

**Access:** https://localhost:8080
- Username: `admin`
- Password: (from command above)

### 3. Install ArgoCD CLI (Optional)

```bash
brew install argocd

# Login
argocd login localhost:8080
```

---

## Deploy Your Application with ArgoCD

### Method 1: Via UI (Easy)

1. Open ArgoCD UI: https://localhost:8080
2. Click **"+ NEW APP"**
3. Fill in:
   - **Application Name:** aec-data-platform
   - **Project:** default
   - **Sync Policy:** Automatic
   - **Repository URL:** https://github.com/YOUR-USERNAME/autodesk-project
   - **Revision:** main
   - **Path:** kubernetes/manifests
   - **Cluster URL:** https://kubernetes.default.svc
   - **Namespace:** aec-data
4. Click **CREATE**

ArgoCD will now automatically deploy and sync your application!

### Method 2: Via Manifest (GitOps Way)

```bash
# Update the repo URL in the manifest
cd ci-cd/argocd
nano application.yaml  # Change YOUR-USERNAME

# Apply
kubectl apply -f application.yaml

# Watch deployment
kubectl get applications -n argocd
argocd app get aec-data-platform
```

---

## How It Works

### The GitOps Flow:

```
1. Developer commits code
   ↓
2. GitHub Actions builds Docker image
   ↓
3. Developer updates K8s manifests with new image tag
   ↓
4. Commits manifest changes to Git
   ↓
5. ArgoCD detects Git changes (every 3 minutes)
   ↓
6. ArgoCD syncs cluster to match Git
   ↓
7. Application updated automatically!
```

### Example Workflow:

```bash
# 1. Update your code
vim services/data-ingestion-service/app/main.py

# 2. Commit and push
git add .
git commit -m "Add new feature"
git push origin main

# 3. GitHub Actions builds new image
# (automatically triggered by push)

# 4. Update K8s manifest with new image tag
cd kubernetes/manifests
sed -i '' "s|image: data-ingestion-service:.*|image: ghcr.io/username/data-ingestion-service:abc123|g" data-ingestion-deployment.yaml

# 5. Commit manifest change
git add data-ingestion-deployment.yaml
git commit -m "Deploy new image version"
git push origin main

# 6. ArgoCD detects change and deploys!
# (within 3 minutes, or click "Sync" in UI for immediate)
```

---

## ArgoCD Commands

### View Applications
```bash
# List all apps
argocd app list

# Get app details
argocd app get aec-data-platform

# View app history
argocd app history aec-data-platform
```

### Sync Operations
```bash
# Manual sync
argocd app sync aec-data-platform

# Sync specific resource
argocd app sync aec-data-platform --resource Deployment:data-ingestion-service

# Hard refresh (ignore cache)
argocd app sync aec-data-platform --force
```

### Rollback
```bash
# View history
argocd app history aec-data-platform

# Rollback to previous version
argocd app rollback aec-data-platform 1
```

### Health & Status
```bash
# Check health
argocd app get aec-data-platform --refresh

# View diff between Git and cluster
argocd app diff aec-data-platform
```

---

## ArgoCD UI Features

### Application View:
- **Tree View** - Visual representation of all resources
- **Network View** - Service dependencies
- **Events** - Kubernetes events
- **Logs** - Pod logs directly in UI

### Sync Status:
- 🟢 **Synced** - Cluster matches Git
- 🟡 **OutOfSync** - Cluster differs from Git
- 🔵 **Progressing** - Deployment in progress
- 🔴 **Degraded** - Health check failing

### Sync Strategies:
- **Auto-sync** - Automatically sync on Git changes
- **Self-heal** - Automatically fix manual changes
- **Prune** - Delete resources removed from Git

---

## Best Practices

### 1. Separate Config Repo (Optional)
```
app-code/ (application code)
app-config/ (Kubernetes manifests)
```

Keeps deployment config separate from code.

### 2. Environment Branches
```
main → production
staging → staging env
develop → dev env
```

### 3. Kustomize or Helm
Instead of raw YAML, use overlays:

```bash
kubernetes/
├── base/          # Common configs
└── overlays/
    ├── dev/       # Dev-specific
    ├── staging/   # Staging-specific
    └── prod/      # Prod-specific
```

### 4. Secret Management
Don't store secrets in Git! Use:
- Sealed Secrets
- External Secrets Operator
- HashiCorp Vault plugin

### 5. Progressive Delivery
Use ArgoCD Rollouts for:
- Canary deployments
- Blue-green deployments
- Traffic splitting

---

## Complete CI/CD Flow

### GitHub Actions + ArgoCD

```yaml
# .github/workflows/ci.yml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Build and push image
      - name: Build Docker image
        run: docker build -t ghcr.io/${{ github.repository }}/app:${{ github.sha }}
      
      - name: Push image
        run: docker push ghcr.io/${{ github.repository }}/app:${{ github.sha }}
      
      # Update K8s manifest
      - name: Update manifest
        run: |
          sed -i "s|image:.*|image: ghcr.io/${{ github.repository }}/app:${{ github.sha }}|g" k8s/deployment.yaml
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add k8s/deployment.yaml
          git commit -m "Update image to ${{ github.sha }}"
          git push
      
      # ArgoCD syncs automatically!
```

---

## Interview Talking Points

**Q: What's GitOps?**
**A:** "GitOps uses Git as the single source of truth for infrastructure. All changes go through Git, providing audit trails, rollback via Git revert, and declarative infrastructure."

**Q: ArgoCD vs Jenkins?**
**A:** "Both are valid. Jenkins is push-based and flexible. ArgoCD is pull-based and Kubernetes-native. ArgoCD excels at keeping clusters in sync with Git. I use both: GitHub Actions/Jenkins for CI (build/test), ArgoCD for CD (deploy)."

**Q: How do you handle secrets?**
**A:** "Never in Git. Use Sealed Secrets for GitOps, or ArgoCD Vault plugin to fetch from HashiCorp Vault at deploy time."

**Q: Multi-cluster?**
**A:** "ArgoCD excels here. One ArgoCD instance can manage dozens of clusters. Define each cluster as a destination in application manifests."

---

## Comparison: Jenkins vs GitHub Actions vs ArgoCD

| Feature | Jenkins | GitHub Actions | ArgoCD |
|---------|---------|----------------|---------|
| **Type** | CI/CD | CI/CD | CD only |
| **Hosting** | Self-hosted | Cloud | Self-hosted |
| **K8s Native** | ❌ | ❌ | ✅ |
| **GitOps** | ❌ | ❌ | ✅ |
| **UI** | Good | Basic | Excellent |
| **Complexity** | High | Low | Medium |
| **Best For** | Enterprise CI/CD | GitHub projects | K8s deployments |

### Your Project Uses All Three:
- ✅ **Jenkins** - Traditional enterprise CI/CD
- ✅ **GitHub Actions** - Modern cloud-native CI
- ✅ **ArgoCD** - GitOps continuous delivery

This demonstrates **breadth of knowledge** and **flexibility**! 🚀

---

## Troubleshooting

### App Stuck OutOfSync
```bash
# Force sync
argocd app sync aec-data-platform --force

# If still stuck, delete and recreate
kubectl delete app aec-data-platform -n argocd
kubectl apply -f application.yaml
```

### ArgoCD Can't Access Git Repo
```bash
# Add Git credentials (for private repos)
argocd repo add https://github.com/username/repo \
  --username <username> \
  --password <token>
```

### Health Check Failing
```bash
# Check app status
argocd app get aec-data-platform

# View events
kubectl get events -n aec-data

# Check specific resource
kubectl describe deployment data-ingestion-service -n aec-data
```

---

## Next Steps

1. **Install ArgoCD locally** (15 minutes)
2. **Deploy your app via ArgoCD** (10 minutes)
3. **Make a change and watch it sync** (5 minutes)
4. **Try a rollback** (2 minutes)
5. **Practice explaining GitOps** (interview prep)

---

**You now have THREE CI/CD approaches:**
1. **Jenkins** - Enterprise standard
2. **GitHub Actions** - Modern cloud
3. **ArgoCD** - Cutting-edge GitOps

**This puts you ahead of most candidates!** 🎯
