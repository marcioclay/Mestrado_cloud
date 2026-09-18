# Passo 1: Preparação do Ambiente e Instalação do Terraform

Este documento faz parte do laboratório prático de Infraestrutura como Código (IaC) utilizando o **Terraform**. O objetivo desta etapa é preparar o seu host ou máquina virtual Ubuntu (versão 22.04 LTS recomendada) com as dependências essenciais e a versão oficial do Terraform da HashiCorp.

---

## 🛠️ Pré-requisitos

* **Sistema Operacional:** Ubuntu 22.04 LTS (ou distribuição baseada em Debian compatível).
* **Permissões:** Acesso a um terminal com privilégios de superusuário (`sudo`).

---

## 📋 Instruções de Instalação

Abra o seu terminal no Ubuntu e execute os comandos abaixo em sequência:

### 1. Atualizar o sistema e instalar dependências básicas
Atualize os pacotes atuais do sistema operacional e instale ferramentas de suporte (como utilitários de rede, compactação e Python):

```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y curl unzip gnupg software-properties-common git python3-pip python3-venv
```

### 2. Adicionar a chave GPG e o repositório oficial da HashiCorp
Baixe a chave criptográfica oficial da HashiCorp e configure o repositório de pacotes dedicado para garantir atualizações seguras:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

### 3. Instalar o Terraform
Atualize o índice de pacotes do gerenciador `apt` e instale o pacote oficial do Terraform:

```bash
sudo apt-get update && sudo apt-get install -y terraform
```

### 4. Verificar a Instalação
Para confirmar se a instalação foi bem-sucedida e se o binário está acessível no PATH do sistema, execute:

```bash
terraform -version
```

---
*Pronto! Com o ambiente preparado e o Terraform instalado, você estará apto para avançar para a criação dos manifestos de infraestrutura (como QEMU/KVM, OCI ou VirtualBox).*