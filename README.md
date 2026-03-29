### kvm-terraform-k8s

Terraform + Ansible automation for spinning up a Kubernetes cluster on KVM/libvirt VMs running Fedora Cloud.

## Stack

- [KVM](https://www.linux-kvm.org/page/Main_Page) - Linux hypervisor
- [Terraform](https://www.terraform.io/) + [terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt) - VM provisioning
- [Ansible](https://www.ansible.com/) - Kubernetes cluster bootstrapping
- [Fedora Cloud](https://alt.fedoraproject.org/cloud/) - VM base image
- [Kubernetes](https://kubernetes.io/) (kubeadm) with [Flannel](https://github.com/flannel-io/flannel) CNI

## Prerequisites

- libvirt/KVM configured on the host
- Terraform >= 1.0
- Ansible
- `jq` (for inventory generation)
- Fedora Cloud qcow2 image downloaded to `/vm/` (update path in `main.tf` if different)

## Quick Start

```bash
# 1. One-time setup
./init_keys.sh          # Generate SSH keys
./bridge0_setup.sh      # Configure bridge network
./kvm_setup.sh          # Setup KVM (if needed)
./create_diskpools.sh   # Create libvirt storage pools

# 2. Deploy everything (VMs + Kubernetes)
./deploy.sh
```

After deployment, use the cluster:
```bash
export KUBECONFIG=$(pwd)/kube-config.yaml
kubectl get nodes
```

## What deploy.sh does

1. `terraform apply` - Creates 1 control plane + 3 worker VMs with cloud-init that installs containerd, kubeadm, kubelet, kubectl
2. `generate_inventory.sh` - Builds Ansible inventory from Terraform outputs
3. `ansible-playbook k8s_setup.yml` - Initializes the control plane, installs Flannel CNI, joins workers

## Default VM Layout

| Role          | Hostname       | IP              | vCPU | RAM  |
|---------------|----------------|-----------------|------|------|
| Control Plane | k8s-cp-0       | 192.168.10.201  | 2    | 4 GB |
| Worker        | k8s-worker-0   | 192.168.10.202  | 2    | 4 GB |
| Worker        | k8s-worker-1   | 192.168.10.203  | 2    | 4 GB |
| Worker        | k8s-worker-2   | 192.168.10.204  | 2    | 4 GB |

Adjust `controlPlaneCount`, `workerCount`, `memoryMB`, `cpu` in `main.tf` or via `terraform.tfvars`.

## Files

| File | Purpose |
|------|---------|
| `deploy.sh` | End-to-end deployment script |
| `main.tf` | Terraform infrastructure (VMs, network, volumes) |
| `cloud_init.cfg` | Cloud-init: users, k8s prerequisites, containerd |
| `ansible/k8s_setup.yml` | Ansible playbook: kubeadm init, CNI, worker join |
| `generate_inventory.sh` | Generates Ansible inventory from Terraform outputs |
| `init_keys.sh` | Generate SSH key pair |
| `bridge0_setup.sh` | Bridge network setup |
| `kvm_setup.sh` | KVM host configuration |
| `create_diskpools.sh` | Create libvirt storage pools |
| `cleanup_tf.sh` | Destroy all VMs and clean state |

## Cleanup

```bash
./cleanup_tf.sh
```
