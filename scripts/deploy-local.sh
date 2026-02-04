#!/bin/bash
# Deploy to local Kubernetes cluster

set -e

echo "🚀 Deploying AEC Data Platform to Kubernetes..."
echo ""

PROJECT_ROOT="/Users/charlie/Desktop/autodesk-project"

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster not accessible"
    echo "Please ensure Kubernetes is enabled in Docker Desktop"
    exit 1
fi

# Create namespace
echo "Creating namespace..."
kubectl create namespace aec-data --dry-run=client -o yaml | kubectl apply -f -

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
cd "$PROJECT_ROOT/kubernetes/manifests"

# Apply in order
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f rabbitmq-deployment.yaml
kubectl apply -f data-ingestion-deployment.yaml
kubectl apply -f data-processing-deployment.yaml
kubectl apply -f data-api-deployment.yaml
kubectl apply -f nginx-ingress.yaml

echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment --all -n aec-data

echo ""
echo "📊 Deployment status:"
kubectl get all -n aec-data

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Access services:"
echo "  kubectl port-forward -n aec-data svc/nginx 8080:80"
