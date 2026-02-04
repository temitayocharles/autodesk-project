# AEC Data Infrastructure DevOps Project

## 🎯 Project Overview

This enterprise-grade project simulates the Architecture, Engineering, and Construction (AEC) Data Infrastructure at Autodesk. You'll build a complete DevOps ecosystem including microservices, CI/CD pipelines, containerization, orchestration, monitoring, and infrastructure automation.

## 📋 Prerequisites

Before starting this project, ensure you have the following installed on your macOS system:

### Required Software & Tools

1. **Docker Desktop** (v4.25+)
   - Install from: https://www.docker.com/products/docker-desktop
   - Includes Docker Engine and Docker Compose
   - Enable Kubernetes in Docker Desktop settings

2. **Homebrew** (macOS Package Manager)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Python 3.11+**
   ```bash
   brew install python@3.11
   ```

4. **Go 1.21+**
   ```bash
   brew install go
   ```

5. **Node.js 20+ & npm**
   ```bash
   brew install node
   ```

6. **Git**
   ```bash
   brew install git
   ```

7. **kubectl** (Kubernetes CLI)
   ```bash
   brew install kubectl
   ```

8. **Helm** (Kubernetes Package Manager)
   ```bash
   brew install helm
   ```

9. **Terraform** (v1.6+)
   ```bash
   brew install terraform
   ```

10. **Jenkins** (Local Installation) - Optional
    ```bash
    brew install jenkins-lts
    ```

11. **ArgoCD CLI** (for GitOps) - Optional
    ```bash
    brew install argocd
    ```

12. **Ansible**
    ```bash
    brew install ansible
    ```

12. **AWS CLI** (for S3 interactions)
    ```bash
    brew install awscli
    aws configure
    ```

13. **Minikube** (Alternative to Docker Desktop Kubernetes)
    ```bash
    brew install minikube
    ```

14. **k9s** (Kubernetes Terminal UI)
    ```bash
    brew install k9s
    ```

15. **jq** (JSON processor)
    ```bash
    brew install jq
    ```

16. **yq** (YAML processor)
    ```bash
    brew install yq
    ```

17. **Vault** (HashiCorp Vault for secrets management)
    ```bash
    brew install vault
    ```

18. **Prometheus & Grafana** (Monitoring - will be deployed via Docker)

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
- **Jenkins** (CI/CD)
- **HashiCorp Vault** (Secrets management)
- **Kubernetes** (Orchestration)

## 📚 Learning Path & Project Phases

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
cd /Users/charlie/Desktop/autodesk-project

# Verify all prerequisites
./scripts/verify-prerequisites.sh

# Start the development environment
./scripts/start-dev-environment.sh

# Build all services
./scripts/build-all.sh

# Deploy to local Kubernetes
./scripts/deploy-local.sh

# Access services
# API Gateway: http://localhost:8080
# Grafana: http://localhost:3000
# Jenkins: http://localhost:8081
# Prometheus: http://localhost:9090
```

## 📖 Directory Structure

```
autodesk-project/
├── README.md                          # This file
├── TUTORIAL.md                        # Step-by-step tutorial
├── services/                          # Microservices
│   ├── data-ingestion-service/       # Python/FastAPI service
│   ├── data-processing-service/      # Go service
│   └── data-api-service/             # Python/Flask service
├── infrastructure/                    # IaC
│   ├── terraform/                    # Terraform configs
│   ├── ansible/                      # Ansible playbooks
│   └── docker-compose/               # Docker Compose files
├── kubernetes/                        # K8s manifests
│   ├── manifests/                    # Raw YAML files
│   └── helm-charts/                  # Helm charts
├── ci-cd/                            # CI/CD configs
│   ├── jenkins/                      # Jenkinsfiles
│   └── scripts/                      # Build scripts
├── monitoring/                        # Observability
│   ├── prometheus/                   # Prometheus configs
│   ├── grafana/                      # Grafana dashboards
│   └── loki/                         # Loki configs
├── security/                         # Security configs
│   ├── vault/                        # Vault policies
│   └── policies/                     # Security policies
├── scripts/                          # Automation scripts
│   ├── verify-prerequisites.sh
│   ├── build-all.sh
│   ├── deploy-local.sh
│   └── cleanup.sh
├── docs/                             # Documentation
│   ├── architecture/
│   ├── runbooks/
│   └── troubleshooting/
└── tests/                            # Integration tests
    ├── load-tests/
    └── e2e-tests/
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
- ✅ CI/CD pipeline design (Jenkins)
- ✅ Infrastructure as Code (Terraform, Ansible)
- ✅ Monitoring & Observability (Prometheus, Grafana, Loki)
- ✅ Security best practices (Vault, RBAC, Network Policies)
- ✅ Cloud integration (AWS S3)
- ✅ Automation & scripting
- ✅ Documentation & communication

## 🤝 Contributing

This is a learning project. Document your learnings and improvements as you progress.

## 📝 License

MIT License - Educational Project

---

**Ready to begin? Start with the TUTORIAL.md file for your guided journey!**
