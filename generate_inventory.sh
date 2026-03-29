#!/bin/bash
# Generate Ansible inventory from Terraform outputs
set -euo pipefail

CP_IPS=$(terraform output -json control_plane_ips | jq -r '.[]')
WORKER_IPS=$(terraform output -json worker_ips | jq -r '.[]')

cat > ansible/inventory.ini <<EOF
[control_plane]
$(echo "$CP_IPS" | while read -r ip; do echo "$ip"; done)

[workers]
$(echo "$WORKER_IPS" | while read -r ip; do echo "$ip"; done)

[k8s:children]
control_plane
workers

[all:vars]
ansible_user=fedora
ansible_ssh_private_key_file=../id_rsa
ansible_ssh_common_args=-o StrictHostKeyChecking=no
EOF

echo "✓ Inventory written to ansible/inventory.ini"
