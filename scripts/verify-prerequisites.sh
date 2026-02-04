#!/bin/bash
# Prerequisite verification script

set -e

echo "🔍 Verifying prerequisites for AEC Data Infrastructure Project..."
echo ""

MISSING=()

# Function to check command
check_command() {
    if command -v "$1" &> /dev/null; then
        VERSION=$($1 $2 2>&1 | head -n 1)
        echo "✅ $3: $VERSION"
    else
        echo "❌ $3 is not installed"
        MISSING+=("$3")
    fi
}

# Check Docker
echo "--- Container & Orchestration ---"
check_command "docker" "--version" "Docker"
check_command "docker-compose" "--version" "Docker Compose"
check_command "kubectl" "version --client --short" "kubectl"
check_command "helm" "version --short" "Helm"
check_command "minikube" "version --short" "Minikube"

echo ""
echo "--- Programming Languages ---"
check_command "python3" "--version" "Python"
check_command "go" "version" "Go"
check_command "node" "--version" "Node.js"
check_command "npm" "--version" "npm"

echo ""
echo "--- Infrastructure Tools ---"
check_command "terraform" "--version" "Terraform"
check_command "ansible" "--version" "Ansible"
check_command "vault" "--version" "HashiCorp Vault"

echo ""
echo "--- CI/CD ---"
if brew services list | grep -q jenkins-lts; then
    echo "✅ Jenkins (installed via Homebrew)"
else
    echo "❌ Jenkins is not installed"
    MISSING+=("Jenkins")
fi

echo ""
echo "--- Cloud & Utilities ---"
check_command "aws" "--version" "AWS CLI"
check_command "jq" "--version" "jq"
check_command "yq" "--version" "yq"
check_command "k9s" "version" "k9s"
check_command "git" "--version" "Git"

echo ""
echo "--- Checking Docker Status ---"
if docker ps &> /dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is not running"
    echo "   Please start Docker Desktop"
    MISSING+=("Docker daemon")
fi

echo ""
echo "--- Checking Kubernetes ---"
if kubectl cluster-info &> /dev/null; then
    echo "✅ Kubernetes cluster is accessible"
    kubectl get nodes
else
    echo "⚠️  Kubernetes cluster not accessible"
    echo "   Enable Kubernetes in Docker Desktop settings"
fi

echo ""
echo "--- Checking AWS Configuration ---"
if [ -f ~/.aws/credentials ]; then
    echo "✅ AWS credentials file exists"
    if aws sts get-caller-identity &> /dev/null; then
        echo "✅ AWS credentials are valid"
    else
        echo "⚠️  AWS credentials may be invalid"
    fi
else
    echo "⚠️  AWS credentials not configured"
    echo "   Run: aws configure"
fi

echo ""
echo "=================================================="
if [ ${#MISSING[@]} -eq 0 ]; then
    echo "✅ All prerequisites are installed!"
    echo ""
    echo "Next steps:"
    echo "1. Configure AWS: aws configure"
    echo "2. Copy .env file: cp infrastructure/docker-compose/.env.example infrastructure/docker-compose/.env"
    echo "3. Edit .env with your AWS credentials and S3 bucket name"
    echo "4. Start services: cd infrastructure/docker-compose && docker-compose up -d"
    exit 0
else
    echo "❌ Missing prerequisites:"
    for item in "${MISSING[@]}"; do
        echo "   - $item"
    done
    echo ""
    echo "Please install missing tools. See README.md for installation instructions."
    exit 1
fi
