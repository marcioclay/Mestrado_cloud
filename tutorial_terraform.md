# Tutorial Prático: Provisionamento Automatizado de Múltiplas VMs com Terraform

Este tutorial foi desenvolvido para atender aos requisitos práticos da disciplina de Cloud Computing, focando no uso de **Infraestrutura como Código (IaC)** com **Terraform** para o provisionamento e gestão de Máquinas Virtuais.

---

## 🛠️ 1. Instalação e Preparação do Terraform

Antes de qualquer provisionamento, é necessário garantir que o binário oficial do Terraform esteja instalado no seu ambiente de trabalho (como uma VM Ubuntu).

### Comandos de Instalação:
Execute os seguintes comandos no terminal:

```bash
# Atualizar pacotes e instalar dependências essenciais
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y curl unzip gnupg software-properties-common git

# Adicionar a chave GPG e o repositório oficial da HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Instalar o Terraform
sudo apt-get update && sudo apt-get install -y terraform

# Verificar a instalação bem-sucedida
terraform -version
```

---

## 🖥️ 2. Item I: Explicação das Opções de SO para a Criação de VMs

Diferente do método tradicional (onde o operador utiliza arquivos ISO interativos e clica manualmente nas telas de instalação), o provisionamento moderno via Terraform em ambientes virtualizados e de nuvem adota uma abordagem otimizada:

1. **Imagens de Nuvem em formato QCOW2 / Box:**
   * Utiliza-se uma imagem base pré-compilada e genérica (como o *Ubuntu 22.04 Server Cloud Image*). O formato `qcow2` (*QEMU Copy On Write*) permite alocação dinâmica de espaço, onde o disco da VM cresce conforme a necessidade a partir de uma imagem base imutável.
2. **Contextualização Dinâmica com Cloud-Init:**
   * Como a imagem base é padronizada e idêntica para qualquer máquina, o Terraform injeta um arquivo de configuração customizado (*Cloud-Init*) no primeiro boot. 
   * Isso permite configurar de forma automatizada:
     * O **hostname** de cada instância de forma individual.
     * A injeção de **chaves públicas SSH** (`id_rsa.pub`), eliminando a necessidade de senhas estáticas e garantindo acesso seguro imediato.
     * A criação automática de usuários administradores com privilégios de `sudo`.

---

## 📦 3. Item II: Como Criar Múltiplas VMs com Terraform

Para evitar a repetição excessiva de código (o que violaria o princípio DRY - *Don't Repeat Yourself*) e permitir a criação simultânea de um cluster completo (por exemplo, 1 *Control Plane* e 2 *Workers* para Kubernetes), o Terraform faz uso de **variáveis locais (`locals`)** em conjunto com a estrutura de repetição **`for_each`**.

### Exemplo Prático de Código HCL (`main.tf`):

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

# 1. Definição centralizada dos nós do cluster usando um mapa (locals)
locals {
  cluster_nodes = {
    "k8s-control-plane" = { role = "control-plane", vcpu = 2, memory = 4096, disk_gb = 20 }
    "k8s-worker-1"      = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
    "k8s-worker-2"      = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
  }
}

# 2. Imagem Base compartilhada
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-22.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 3. Criação dinâmica de múltiplos discos utilizando for_each sobre os locals
resource "libvirt_volume" "vm_disks" {
  for_each       = local.cluster_nodes
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = each.value.disk_gb * 1073741824
}

# 4. Provisionamento simultâneo das Máquinas Virtuais baseadas no mapa
resource "libvirt_domain" "cluster_vms" {
  for_each = local.cluster_nodes
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  disk {
    volume_id = libvirt_volume.vm_disks[each.key].id
  }
}
```

### Como o `for_each` funciona na prática:
* O Terraform lê o dicionário `cluster_nodes` iterando chave por chave (`k8s-control-plane`, `k8s-worker-1`, `k8s-worker-2`).
* Para cada item, ele extrai os parâmetros específicos (memória RAM, vCPU, tamanho do disco) e instancia os recursos em paralelo com um único comando de execução.

---

## 🚀 4. Fluxo de Execução do Tutorial

Para colocar a infraestrutura em funcionamento, execute os comandos abaixo no diretório do projeto:

1. **Inicializar o diretório de trabalho e descarregar os provedores:**
   ```bash
   terraform init
   ```
2. **Visualizar o plano de execução (o que será criado):**
   ```bash
   terraform plan
   ```
3. **Aplicar e provisionar a infraestrutura de forma automatizada:**
   ```bash
   terraform apply -auto-approve
   ```
4. **Destruir o ambiente quando finalizado:**
   ```bash
   terraform destroy -auto-approve
   ```