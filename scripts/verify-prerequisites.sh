#!/bin/bash
# Prerequisite verification script

set -e

echo "🔍 Verifying prerequisites for AEC Data Infrastructure Project..."
echo ""

MISSING_REQUIRED=()
MISSING_OPTIONAL=()

# Function to check command
check_command() {
    local cmd="$1"
    local args="$2"
    local label="$3"
    local required="$4"

    if command -v "$cmd" &> /dev/null; then
        VERSION=$($cmd $args 2>&1 | head -n 1)
        echo "✅ $label: $VERSION"
    else
        if [ "$required" = "required" ]; then
            echo "❌ $label is not installed (required)"
            MISSING_REQUIRED+=("$label")
        else
            echo "⚠️  $label is not installed (optional)"
            MISSING_OPTIONAL+=("$label")
        fi
    fi
}

# Required for running the platform via Docker Compose
echo "--- Core Requirements ---"
check_command "docker" "--version" "Docker" "required"
check_command "docker-compose" "--version" "Docker Compose" "required"
check_command "aws" "--version" "AWS CLI" "required"
check_command "jq" "--version" "jq" "required"
check_command "git" "--version" "Git" "required"

echo ""
echo "--- Optional (Local Development) ---"
check_command "python3" "--version" "Python" "optional"
check_command "go" "version" "Go" "optional"
check_command "node" "--version" "Node.js" "optional"
check_command "npm" "--version" "npm" "optional"

echo ""
echo "--- Optional (Kubernetes & IaC) ---"
check_command "kubectl" "version --client --short" "kubectl" "optional"
check_command "helm" "version --short" "Helm" "optional"
check_command "minikube" "version --short" "Minikube" "optional"
check_command "terraform" "--version" "Terraform" "optional"
check_command "ansible" "--version" "Ansible" "optional"
check_command "vault" "--version" "HashiCorp Vault" "optional"
check_command "yq" "--version" "yq" "optional"
check_command "k9s" "version" "k9s" "optional"

echo ""
echo "--- Optional (CI/CD Tools) ---"
if command -v brew &> /dev/null; then
    if brew services list | grep -q jenkins-lts; then
        echo "✅ Jenkins (installed via Homebrew)"
    else
        echo "⚠️  Jenkins is not installed (optional)"
        MISSING_OPTIONAL+=("Jenkins")
    fi
else
    echo "⚠️  Homebrew not detected; skipping Jenkins check (optional)"
fi

echo ""
echo "--- Checking Docker Status ---"
if docker ps &> /dev/null; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Docker daemon is not running"
    echo "   Please start Docker Desktop"
    MISSING_REQUIRED+=("Docker daemon")
fi

echo ""
echo "--- Checking Kubernetes ---"
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        echo "✅ Kubernetes cluster is accessible"
        kubectl get nodes
    else
        echo "⚠️  Kubernetes cluster not accessible (optional)"
        echo "   Enable Kubernetes in Docker Desktop settings if you plan to run ./scripts/deploy-local.sh"
    fi
else
    echo "⚠️  kubectl not installed (optional)"
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
if [ ${#MISSING_REQUIRED[@]} -eq 0 ]; then
    echo "✅ Required prerequisites are installed!"
    echo ""
    echo "Next steps:"
    echo "1. Configure AWS: aws configure"
    echo "2. Copy .env file: cp infrastructure/docker-compose/.env.example infrastructure/docker-compose/.env"
    echo "3. Edit .env with your AWS credentials and S3 bucket name"
    echo "4. Start services: cd infrastructure/docker-compose && docker-compose up -d"
    if [ ${#MISSING_OPTIONAL[@]} -ne 0 ]; then
        echo ""
        echo "Optional tools not installed:"
        for item in "${MISSING_OPTIONAL[@]}"; do
            echo "   - $item"
        done
    fi
    exit 0
else
    echo "❌ Missing required prerequisites:"
    for item in "${MISSING_REQUIRED[@]}"; do
        echo "   - $item"
    done
    echo ""
    echo "Please install missing tools. See README.md for installation instructions."
    exit 1
fi
