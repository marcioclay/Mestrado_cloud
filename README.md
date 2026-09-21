# Laboratório: Infraestrutura como Código (IaC) com Terraform

Este repositório documenta a resolução do laboratório prático de provisionamento de Máquinas Virtuais utilizando Terraform (focado no provedor QEMU/KVM). Os passos detalhados de preparação do ambiente e o código HCL encontram-se nos tutoriais gerados anteriormente.

Em atendimento aos requisitos da disciplina, abaixo estão os conceitos centrais explorados na prática:

## I. Opções de Sistema Operacional (SO) para Criação de VMs
Na automação com Terraform, não instalamos o SO do zero via ISO. O processo funciona da seguinte forma:
* **Imagens Cloud (QCOW2):** Utilizamos imagens base otimizadas para nuvem (como o Ubuntu Server Cloud Image), que são muito mais leves e rápidas de iniciar.
* **Automação com Cloud-Init:** O Terraform utiliza o Cloud-Init para configurar a máquina no momento do primeiro boot. É através dele que injetamos dinamicamente configurações como o *hostname*, criação do utilizador `ubuntu` e chaves SSH para acesso remoto sem senha.

## II. Criação de Múltiplas VMs Simultaneamente
Para criar uma infraestrutura com várias máquinas (ex: um cluster com 1 Control Plane e 2 Workers) sem repetir grandes blocos de código, utilizamos as seguintes funções do Terraform:
* **Mapeamento (`locals`):** Definimos um dicionário de dados contendo as características de cada nó do cluster (vCPUs, memória RAM e disco).
* **Laço de repetição (`for_each`):** No bloco de criação do recurso (`libvirt_domain`), usamos a diretiva `for_each` para iterar sobre o dicionário local. Assim, com um único `terraform apply`, o Terraform provisiona e configura todas as VMs paralelamente.

  ---

  Imagens:

   <img width="1200" height="543" alt="1" src="https://github.com/user-attachments/assets/b1736c65-f116-4f0d-9163-32ca98b0a0a0" />

   <img width="1200" height="543" alt="2" src="https://github.com/user-attachments/assets/7c47d63f-d25a-4db4-a524-b016429b87f5" />


