terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "hostname" { default = "k8s-node" }
variable "memoryMB" { default = 1024 * 4 }
variable "cpu" { default = 2 }
variable "controlPlaneCount" { default = 1 }
variable "workerCount" { default = 3 }
variable "network" { default = "kvmnet" }
variable "bridge" { default = "bridge0" }

locals {
  totalCount = var.controlPlaneCount + var.workerCount
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  pool   = "default"
  # Suggestion is to download the image and then call locally to save from download timeout"
  #source = "https://dl.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"
  source = "file:///vm/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
}

resource "libvirt_volume" "server_volume" {
  count          = local.totalCount
  pool           = "default"
  name           = "server_volume-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  format         = "qcow2"
}

resource "libvirt_volume" "spare_volume" {
  count  = local.totalCount
  pool   = "vmdata"
  name   = "spare_volume-${count.index}"
  format = "qcow2"
  size   = 107374182400
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count     = local.totalCount
  name      = "${var.hostname}-commoninit-${count.index}.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    hostname = count.index < var.controlPlaneCount ? "k8s-cp-${count.index}" : "k8s-worker-${count.index - var.controlPlaneCount}"
  })
}

resource "libvirt_network" "network" {
  name      = var.network
  mode      = "bridge"
  autostart = true
  addresses = ["192.168.10.0/24"]
  bridge    = var.bridge
}

resource "libvirt_domain" "domain" {
  count      = local.totalCount
  name       = count.index < var.controlPlaneCount ? "k8s-cp-${count.index}" : "k8s-worker-${count.index - var.controlPlaneCount}"
  memory     = var.memoryMB
  vcpu       = var.cpu
  qemu_agent = true
  autostart  = true

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.server_volume.*.id, count.index)
  }

  disk {
    volume_id = element(libvirt_volume.spare_volume.*.id, count.index)
  }

  network_interface {
    network_name   = var.network
    bridge         = var.bridge
    addresses      = ["192.168.10.20${count.index + 1}"]
    mac            = "52:54:00:00:00:a${count.index + 1}"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  depends_on = [
    libvirt_network.network,
  ]

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id
}

output "control_plane_ips" {
  value = [for i, domain in libvirt_domain.domain : domain.network_interface[0].addresses[0] if i < var.controlPlaneCount]
}

output "worker_ips" {
  value = [for i, domain in libvirt_domain.domain : domain.network_interface[0].addresses[0] if i >= var.controlPlaneCount]
}
