# Implantação de Cluster Kubernetes (Terraform + Ansible)

Este projeto documenta a criação e configuração automatizada de um cluster Kubernetes, implementando a separação de responsabilidades entre infraestrutura e configuração.

## Arquitetura Provisionada
A topologia definida no código provisiona **3 máquinas virtuais independentes** (baseadas em imagem cloud do Ubuntu) no hipervisor QEMU/KVM:
* **1x VM Gerente (Control Plane):** `k8s-manager` (4GB RAM, 2 vCPUs, 20GB Disco)
* **2x VMs Workers:** `k8s-worker-1` e `k8s-worker-2` (2GB RAM, 2 vCPUs, 15GB Disco cada)

## Organização e Etapas da Implantação

O projeto está estruturado em dois diretórios complementares:

### 1. `/terraform` (Infraestrutura)
Responsável por criar a "camada de ferro" (hardware virtual) necessária para o cluster. 
* `variables.tf`: Define as funções (manager/worker) e os recursos de hardware de cada nó.
* `main.tf`: Provisiona os volumes `qcow2`, a rede NAT e utiliza o Cloud-Init para injetar configurações básicas de sistema operacional e acessos SSH.
* `outputs.tf`: Mapeia e exporta os IPs atribuídos a cada VM para serem utilizados pela ferramenta de configuração.

### 2. `/ansible` (Configuração e Software)
Responsável por instalar e interligar os componentes do Kubernetes (K3s) nas VMs provisionadas.
* **Origem dos Ficheiros:** Os manifestos de automação presentes nesta pasta (`ansible.cfg`, `hosts.yaml`, `k8s_deploy.yaml`, `vars.yaml`) foram integrados a partir do repositório de referência da disciplina (`mnstrlara/k8s-terrable`). Eles funcionam de forma padronizada para ler o inventário de IPs gerado pelo Terraform e executar o *deploy* do cluster automaticamente.
