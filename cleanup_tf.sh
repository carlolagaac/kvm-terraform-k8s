#!/bin/bash
# Cleanup all Terraform and Kubernetes resources
set -euo pipefail

echo "Shutting down VMs..."
for vm in $(sudo virsh list --name 2>/dev/null); do
  sudo virsh shutdown "$vm" 2>/dev/null || true
done

sleep 5

echo "Destroying and undefining VMs..."
for vm in $(sudo virsh list --all --name 2>/dev/null); do
  sudo virsh destroy "$vm" 2>/dev/null || true
  sudo virsh undefine "$vm" 2>/dev/null || true
done

echo "Removing network..."
sudo virsh net-destroy kvmnet 2>/dev/null || true
sudo virsh net-undefine kvmnet 2>/dev/null || true

echo "Cleaning Terraform state..."
rm -rf .terraform* terraform*

echo "Cleaning generated files..."
rm -f kube-config.yaml ansible/inventory.ini

echo "✓ Cleanup complete"
