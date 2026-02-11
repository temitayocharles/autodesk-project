# AEC Data Infrastructure DevOps Project


## Start Here
- Read [START_HERE.md](START_HERE.md) for the chronological playbook.


## Documentation Index
- [7-DAY-PLAN.md](7-DAY-PLAN.md)
- [GETTING-STARTED.md](GETTING-STARTED.md)
- [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md)
- [START-HERE.md](START-HERE.md)
- [TUTORIAL.md](TUTORIAL.md)
- [WHATS-NEW.md](WHATS-NEW.md)
- [ci-cd/argocd/ARGOCD-GUIDE.md](ci-cd/argocd/ARGOCD-GUIDE.md)
- [ci-cd/jenkins/SETUP.md](ci-cd/jenkins/SETUP.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/INTERVIEW-PREP.md](docs/INTERVIEW-PREP.md)

## 🎯 Project Overview

This enterprise-grade project simulates the Architecture, Engineering, and Construction (AEC) Data Infrastructure at Autodesk. You'll build a complete DevOps ecosystem including microservices, CI/CD pipelines, containerization, orchestration, monitoring, and infrastructure automation.

## 📋 Prerequisites

Before starting this project, ensure you have the following installed on your macOS system.

### Core (Required to Run the Platform via Docker Compose)

1. **Docker Desktop** (v4.25+)
   - Install from: https://www.docker.com/products/docker-desktop
   - Includes Docker Engine and Docker Compose
   - Optional: Enable Kubernetes in Docker Desktop settings (only needed for `./scripts/deploy-local.sh`)

2. **Homebrew** (macOS Package Manager)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **AWS CLI** (for S3 interactions)
   ```bash
   brew install awscli
   aws configure
   ```

4. **jq** (JSON processor)
   ```bash
   brew install jq
   ```

5. **Git**
   ```bash
   brew install git
   ```

### Optional (Needed Only for Local Development or Advanced Sections)

6. **Python 3.11+** (only needed if running services locally outside Docker)
   ```bash
   brew install python@3.11
   ```

7. **Go 1.21+** (only needed if running the Go service locally)
   ```bash
   brew install go
   ```

8. **Node.js 20+ & npm** (only needed for tooling or future frontend work)
   ```bash
   brew install node
   ```

9. **kubectl** (Kubernetes CLI; required for `./scripts/deploy-local.sh`)
   ```bash
   brew install kubectl
   ```

10. **Helm** (Kubernetes Package Manager; optional)
    ```bash
    brew install helm
    ```

11. **Terraform** (optional; not used in the current repo)
    ```bash
    brew install terraform
    ```

12. **Ansible** (optional; not used in the current repo)
    ```bash
    brew install ansible
    ```

13. **Jenkins** (optional; local install for experimentation)
    ```bash
    brew install jenkins-lts
    ```

14. **ArgoCD CLI** (optional; for GitOps experimentation)
    ```bash
    brew install argocd
    ```

15. **Minikube** (optional; alternative to Docker Desktop Kubernetes)
    ```bash
    brew install minikube
    ```

16. **k9s** (optional; Kubernetes terminal UI)
    ```bash
    brew install k9s
    ```

17. **yq** (optional; YAML processor)
    ```bash
    brew install yq
    ```

18. **Vault** (optional; secrets management experimentation)
    ```bash
    brew install vault
    ```

### Optional but Recommended

19. **Visual Studio Code** with extensions:
    - Docker
    - Kubernetes
    - Python
    - Go
    - Terraform
    - YAML

20. **Postman or curl** for API testing

### AWS Account Setup

- Ensure you have an AWS account with an S3 bucket created
- Configure AWS credentials: `aws configure`
- Note your S3 bucket name for the project

## 🏗️ Project Architecture

This project implements a microservices architecture for an AEC Data Platform with the following components:

**All services available as pre-built Docker images from GitHub Container Registry:**
- `ghcr.io/temitayocharles/autodesk-project/data-ingestion-service:main`
- `ghcr.io/temitayocharles/autodesk-project/data-processing-service:main`
- `ghcr.io/temitayocharles/autodesk-project/data-api-service:main`

### Microservices (3 Services)

1. **Data Ingestion Service** (Python/FastAPI)
   - Handles file uploads (CAD, BIM files simulation)
   - Validates and processes data
   - Stores metadata in PostgreSQL
   - Uploads files to S3

2. **Data Processing Service** (Go)
   - Processes AEC data
   - Performs data transformations
   - Publishes events to message queue

3. **Data API Service** (Python/Flask)
   - RESTful API for data retrieval
   - Authentication & authorization
   - Rate limiting and caching

### Infrastructure Components

- **PostgreSQL Database** (containerized)
- **Redis Cache** (containerized)
- **RabbitMQ Message Queue** (containerized)
- **Nginx** (API Gateway/Load Balancer)
- **Prometheus** (Metrics collection)
- **Grafana** (Visualization)
- **Loki** (Log aggregation)
- **Kubernetes** (Orchestration via manifests)
- **CI/CD** (GitHub Actions workflow + Jenkins/ArgoCD docs and examples)

## 📚 Learning Path & Project Phases

**Note:** Phases that mention tools not present in this repo (Terraform, Ansible, Helm, Vault, etc.) are conceptual learning guidance unless you add those files yourself.

### Phase 1: Application Development (Days 1-3)
- Build the 3 microservices
- Implement business logic
- Write unit tests
- Create Dockerfiles

### Phase 2: Containerization (Days 4-5)
- Create Docker images
- Set up Docker Compose for local development
- Implement multi-stage builds
- Optimize image sizes

### Phase 3: CI/CD Pipeline (Days 6-8)
- Configure Jenkins
- Create Jenkinsfile for each service
- Implement automated testing
- Set up container registry
- Create deployment pipelines

### Phase 4: Infrastructure as Code (Days 9-11)
- Write Terraform configurations
- Create Ansible playbooks
- Implement configuration management
- Set up local infrastructure

### Phase 5: Kubernetes Orchestration (Days 12-15)
- Create Kubernetes manifests
- Implement Helm charts
- Configure services, deployments, ingress
- Set up autoscaling
- Implement health checks

### Phase 6: Monitoring & Observability (Days 16-18)
- Deploy Prometheus & Grafana
- Create custom dashboards
- Set up alerting rules
- Implement distributed tracing
- Configure log aggregation

### Phase 7: Security Implementation (Days 19-21)
- Implement HashiCorp Vault
- Set up secrets management
- Configure RBAC in Kubernetes
- Implement network policies
- Scan containers for vulnerabilities

### Phase 8: Automation & Scripting (Days 22-24)
- Create automation scripts (Python, Bash)
- Implement backup/restore procedures
- Create troubleshooting tools
- Automate routine tasks

### Phase 9: Testing & Validation (Days 25-27)
- Load testing
- Chaos engineering experiments
- Disaster recovery testing
- Security testing

### Phase 10: Documentation & Best Practices (Days 28-30)
- Complete runbooks
- Create architecture diagrams
- Document troubleshooting guides
- Code review and refactoring

## 🚀 Quick Start

```bash
# Clone or navigate to project directory
cd /path/to/autodesk-project

# Verify all prerequisites
./scripts/verify-prerequisites.sh

# Create env file for Docker Compose
cd infrastructure/docker-compose
cp .env.example .env
# Edit .env with your AWS credentials and S3 bucket

# Start the development environment
cd /path/to/autodesk-project
./scripts/start-dev-environment.sh

# Build locally instead of pulling images
# USE_LOCAL_IMAGES=1 ./scripts/start-dev-environment.sh

# Deploy to local Kubernetes
./scripts/deploy-local.sh

# Access services
# API Gateway: http://localhost:8080
# Grafana: http://localhost:3000
# Prometheus: http://localhost:9090
```

## 📖 Directory Structure

```
autodesk-project/
├── README.md                          # This file
├── START-HERE.md                      # Orientation and reading order
├── GETTING-STARTED.md                 # Quick start guide
├── TUTORIAL.md                        # Step-by-step tutorial
├── PROJECT-SUMMARY.md                 # Summary and roadmap
├── services/                          # Microservices
│   ├── data-ingestion-service/        # Python/FastAPI service
│   ├── data-processing-service/       # Go service
│   └── data-api-service/              # Python/Flask service
├── infrastructure/
│   └── docker-compose/                # Docker Compose files and configs
├── kubernetes/
│   └── manifests/                     # Kubernetes YAML manifests
├── ci-cd/
│   ├── argocd/                        # GitOps (ArgoCD)
│   └── jenkins/                       # Jenkins pipeline + setup docs
├── .github/workflows/                 # GitHub Actions CI/CD workflow
├── scripts/                           # Automation scripts
│   ├── verify-prerequisites.sh
│   ├── build-all.sh
│   ├── start-dev-environment.sh
│   ├── test-services.sh
│   ├── deploy-local.sh
│   └── cleanup.sh
└── docs/                              # Documentation
    ├── ARCHITECTURE.md
    └── INTERVIEW-PREP.md
```

## 🎓 Tutorial Mode

Follow the **TUTORIAL.md** file for step-by-step guidance through each phase of the project. Each section includes:
- Detailed explanations
- Code walkthroughs
- Commands to execute
- Expected outputs
- Troubleshooting tips
- Best practices

## 📊 Key Metrics & KPIs

This project demonstrates proficiency in:
- ✅ Multi-language programming (Python, Go, Shell)
- ✅ Container orchestration (Docker, Kubernetes)
- ✅ CI/CD pipeline design (Jenkins, GitHub Actions, ArgoCD)
- ✅ Monitoring & Observability (Prometheus, Grafana, Loki via Docker Compose)
- ✅ Security best practices (RBAC/network policies as planned)
- ✅ Cloud integration (AWS S3)
- ✅ Automation & scripting
- ✅ Documentation & communication

## 🤝 Contributing

This is a learning project. Document your learnings and improvements as you progress.

## 📝 License

MIT License - Educational Project

---

**Ready to begin? Start with the TUTORIAL.md file for your guided journey!**
