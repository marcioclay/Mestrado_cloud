variable "cluster_nodes" {
  description = "Configuração das VMs do cluster"
  type = map(object({
    role    = string
    vcpu    = number
    memory  = number
    disk_gb = number
  }))
  default = {
    "k8s-manager"  = { role = "manager", vcpu = 2, memory = 4096, disk_gb = 20 }
    "k8s-worker-1" = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
    "k8s-worker-2" = { role = "worker", vcpu = 2, memory = 2048, disk_gb = 15 }
  }
}
