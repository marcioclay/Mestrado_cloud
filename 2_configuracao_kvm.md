# Passo 2: Configuração do KVM/QEMU e Provisionamento de Cluster de VMs (Libvirt)

Nesta etapa do laboratório, vamos preparar o hipervisor local baseado em **KVM/QEMU** e criar um manifesto completo em HCL (`main.tf`) utilizando o provedor `dmacvicar/libvirt`. O objetivo é provisionar automaticamente um cluster de 3 nós pronto para Kubernetes (1 *Control Plane* e 2 *Workers*) utilizando imagens do Ubuntu e configuração via Cloud-Init.

---

## 🛠️ 1. Preparação do Hipervisor no Host

Abra o seu terminal no Ubuntu e execute os comandos abaixo para instalar as ferramentas de virtualização e habilitar o serviço do Libvirt:

```bash
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER && newgrp libvirt
```

---

## 📄 2. Manifesto Terraform do Cluster (`main.tf`)

Crie um diretório para o projeto, acesse-o e crie um arquivo chamado `main.tf` com o conteúdo abaixo:

```hcl
terraform {
  required_version = ">= 1.0.0"
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

# Configuração dos Nós do Cluster
locals {
  cluster_nodes = {
    "k8s-control-plane" = { role = "control-plane", vcpu = 2, memory = 4096, disk_gb = 20 }
    "k8s-worker-1"      = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
    "k8s-worker-2"      = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
  }
}

# Imagem Base do Ubuntu Cloud
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Discos Individuais para cada VM
resource "libvirt_volume" "vm_disks" {
  for_each       = local.cluster_nodes
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = each.value.disk_gb * 1073741824
}

# Disco de Inicialização Cloud-Init (Configuração de Usuário e SSH)
resource "libvirt_cloudinit_disk" "cluster_init" {
  for_each = local.cluster_nodes
  name     = "${each.key}-init.iso"
  pool     = "default"
  user_data = <<-EOF
  #cloud-config
  hostname: ${each.key}
  fqdn: ${each.key}.k8s.local
  manage_etc_hosts: true
  users:
    - name: ubuntu
      sudo: ALL=(ALL) NOPASSWD: ALL
      groups: users, admin
      home: /home/ubuntu
      shell: /bin/bash
      ssh_authorized_keys:
        - ${file("~/.ssh/id_rsa.pub")}
  ssh_pwauth: true
  disable_root: false
  EOF
}

# Rede NAT Dedicada
resource "libvirt_network" "cluster_net" {
  name      = "qemu_cluster_net"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["192.168.100.0/24"]
  dhcp { enabled = true }
  dns  { enabled = true }
}

# Provisionamento das Máquinas Virtuais (Domínios)
resource "libvirt_domain" "cluster_vms" {
  for_each  = local.cluster_nodes
  name      = each.key
  memory    = each.value.memory
  vcpu      = each.value.vcpu
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

# Output com o Resumo dos IPs e Informações do Cluster
output "cluster_summary" {
  value = {
    for name, vm in libvirt_domain.cluster_vms : name => {
      role = local.cluster_nodes[name].role
      ip   = vm.network_interface[0].addresses[0]
      ram  = "${local.cluster_nodes[name].memory} MB"
    }
  }
}
```

---

## 🚀 3. Fluxo de Execução do Terraform

Com o arquivo `main.tf` salvo, execute os comandos tradicionais do Terraform para subir o ambiente:

1. **Inicializar o diretório de trabalho e baixar o provedor Libvirt:**
   ```bash
   terraform init
   ```

2. **Revisar o plano de infraestrutura:**
   ```bash
   terraform plan
   ```

3. **Aplicar e provisionar o cluster de VMs:**
   ```bash
   terraform apply -auto-approve
   ```

*Pronto! Seu ambiente KVM/QEMU estará executando as três máquinas virtuais gerenciadas via Infraestrutura como Código.*