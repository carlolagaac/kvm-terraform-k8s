#!/bin/bash
# Full deployment: Terraform VMs + Kubernetes cluster setup
set -euo pipefail

echo "=== Deploying VMs with Terraform ==="
terraform init
terraform apply -auto-approve

echo ""
echo "=== Generating Ansible inventory ==="
./generate_inventory.sh

echo ""
echo "=== Setting up Kubernetes cluster ==="
cd ansible
ansible-playbook -i inventory.ini k8s_setup.yml
cd ..

echo ""
echo "=== Cluster ready ==="
echo "Kubeconfig saved to kube-config.yaml"
echo "Usage: export KUBECONFIG=$(pwd)/kube-config.yaml"
echo ""
kubectl --kubeconfig=kube-config.yaml get nodes
