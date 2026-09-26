output "manager_ip" {
  description = "Endereço IP da VM Gerente"
  value = { for k, v in libvirt_domain.cluster_vms : k => v.network_interface[0].addresses[0] if var.cluster_nodes[k].role == "manager" }
}

output "worker_ips" {
  description = "Endereços IP das VMs Workers"
  value = { for k, v in libvirt_domain.cluster_vms : k => v.network_interface[0].addresses[0] if var.cluster_nodes[k].role == "worker" }
}
