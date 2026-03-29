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

echo "Removing storage volumes..."
for vol in $(sudo virsh vol-list default --details 2>/dev/null | awk 'NR>2 {print $1}' | grep -E 'commoninit|server_volume|os_image'); do
  sudo virsh vol-delete "$vol" --pool default 2>/dev/null || true
done
for vol in $(sudo virsh vol-list vmdata --details 2>/dev/null | awk 'NR>2 {print $1}' | grep 'spare_volume'); do
  sudo virsh vol-delete "$vol" --pool vmdata 2>/dev/null || true
done

echo "Cleaning Terraform state..."
rm -rf .terraform* terraform*

echo "Cleaning generated files..."
rm -f kube-config.yaml ansible/inventory.ini

echo "✓ Cleanup complete"
