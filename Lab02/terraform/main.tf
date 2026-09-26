terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "vm_disks" {
  for_each       = var.cluster_nodes
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = each.value.disk_gb * 1073741824
}

resource "libvirt_cloudinit_disk" "cluster_init" {
  for_each = var.cluster_nodes
  name     = "${each.key}-init.iso"
  pool     = "default"
  user_data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    manage_etc_hosts: true
    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: users, admin
        home: /home/ubuntu
        shell: /bin/bash
    ssh_pwauth: true
  EOF
}

resource "libvirt_network" "cluster_net" {
  name      = "qemu_cluster_net"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["192.168.100.0/24"]
  dhcp { enabled = true }
  dns { enabled = true }
}

resource "libvirt_domain" "cluster_vms" {
  for_each = var.cluster_nodes
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu
  cloudinit = libvirt_cloudinit_disk.cluster_init[each.key].id

  network_interface {
    network_id     = libvirt_network.cluster_net.id
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
