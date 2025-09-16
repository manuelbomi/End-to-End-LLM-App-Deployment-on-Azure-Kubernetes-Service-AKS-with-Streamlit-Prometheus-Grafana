#!/bin/bash
set -e

echo "🔍 Checking if kubectl is installed..."
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl is not installed. Please install it first."
  exit 1
fi

echo "🔍 Checking current Kubernetes context..."
CONTEXT=$(kubectl config current-context 2>/dev/null || true)
if [ -z "$CONTEXT" ]; then
  echo "❌ No Kubernetes context is set. Please connect to your cluster (e.g., AKS)."
  exit 1
fi

echo "📡 Current context: $CONTEXT"
read -p "⚠️  Are you sure you want to deploy to this cluster? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "❌ Aborted."
  exit 1
fi

echo "🔧 Installing or upgrading cert-manager via Helm..."
helm repo add jetstack https://charts.jetstack.io || true
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

echo "✅ cert-manager installed or upgraded."

echo "🔐 Applying Let's Encrypt STAGING ClusterIssuer..."
kubectl apply -f clusterissuer-staging.yaml

echo "📦 Deploying full stack (namespace: llm-system)..."
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-pvcs.yaml
kubectl apply -f 02-secrets.yaml
kubectl apply -f 03-configmap.yaml
kubectl apply -f 04-deployments.yaml
kubectl apply -f 05-services.yaml
kubectl apply -f 06-ingress.yaml

echo "⏳ Waiting 30 seconds for cert-manager to issue staging certs..."
sleep 30

echo "🔎 Checking certs..."
kubectl get certificates -n llm-system
kubectl describe certificate streamlit-tls -n llm-system || true

echo ""
echo "✅ Staging deployment complete."
echo "📌 Visit your apps:"
echo "   https://app.emmanueloyekanluprojects.com"
echo "   https://prometheus.emmanueloyekanluprojects.com"
echo "   https://grafana.emmanueloyekanluprojects.com"
echo ""
echo "⚠️  When HTTPS is working, switch to production by running:"
echo "   kubectl apply -f clusterissuer-prod.yaml"
echo "   kubectl apply -f 06-ingress.yaml"
echo ""
echo "🔥 You're live with production TLS at that point!"
