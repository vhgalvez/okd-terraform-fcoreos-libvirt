# terraform/outputs.tf

#############################################
# MAPA COMPLETO DE IPs
#############################################
output "vm_ips" {
  description = "IPs de todas las máquinas virtuales"
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
}

#############################################
# OUTPUTS INDIVIDUALES
#############################################
output "infra_ip" {
  description = "IP del nodo infra (DNS + NTP)"
  value       = var.infra.ip
}

output "bootstrap_ip" {
  description = "IP del nodo bootstrap"
  value       = var.bootstrap.ip
}

output "master_ip" {
  description = "IP del nodo master"
  value       = var.master.ip
}

output "worker_ip" {
  description = "IP del nodo worker"
  value       = var.worker.ip
}

#############################################
# RED Y DOMINIO
#############################################
output "network_name" {
  value       = var.network_name
  description = "Nombre de la red libvirt"
}

output "network_cidr" {
  value       = var.network_cidr
  description = "CIDR de la red libvirt"
}

#############################################
# POOL — Ruta real usada por libvirt (0.9.1)
#############################################
output "libvirt_pool_path" {
  description = "Ruta del pool de libvirt donde se guardan los discos"
  value       = libvirt_pool.okd.target.path
}
