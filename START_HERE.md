# Start Here

This guide is the shortest path to running, deploying, and maintaining this repo. It is written for future‑you with zero context. Follow in order.

## 1. What This Repo Is
See README for the purpose and context.

## 2. Repo Map (What Lives Where)
- [README.md](README.md): High‑level overview.
- Documentation index (read in order): [docs/INDEX.md](docs/INDEX.md)
- Scripts: [scripts/build-all.sh](scripts/build-all.sh), [scripts/cleanup.sh](scripts/cleanup.sh), [scripts/deploy-local.sh](scripts/deploy-local.sh), [scripts/start-dev-environment.sh](scripts/start-dev-environment.sh), [scripts/test-services.sh](scripts/test-services.sh), [scripts/verify-prerequisites.sh](scripts/verify-prerequisites.sh)

## 3. Quick Local Run
Use the README for local run steps. No Docker Compose file was detected here.

## 5. Config and Secrets
Non‑secret config examples:
- [infrastructure/docker-compose/.env.example](infrastructure/docker-compose/.env.example)
Root env contract:
- [.env.example](.env.example)
Secrets should be stored in Vault; keep only examples here.

## 7. CI/CD
Workflows in this repo:
- [.github/workflows/ci.yml](.github/workflows/ci.yml)
If this repo consumes shared workflows, see the shared workflows repo.

## 8. Troubleshooting
- If a build fails, check README and CI logs first.
- Confirm your local env vars match `.env.example`.
- For Kubernetes: check `kubectl get pods` and `kubectl describe` first.
