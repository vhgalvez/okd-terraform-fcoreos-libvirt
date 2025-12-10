# terraform/outputs.tf
###############################################
# OUTPUTS DEL CLÚSTER OKD (Multimaster)
###############################################

# Ruta real del pool libvirt
output "libvirt_pool_path" {
  value = libvirt_pool.okd.target
}

# Información de red
output "network_name" {
  value = var.network_name
}

output "network_cidr" {
  value = var.network_cidr
}

###############################################
# IPs individuales
###############################################

output "infra_ip" {
  description = "IP del nodo infra (DNS + LB)"
  value       = var.infra.ip
}

output "bootstrap_ip" {
  description = "IP del nodo bootstrap"
  value       = var.bootstrap.ip
}

output "master1_ip" {
  description = "IP del Master 1"
  value       = var.master1.ip
}

output "master2_ip" {
  description = "IP del Master 2"
  value       = var.master2.ip
}

output "master3_ip" {
  description = "IP del Master 3"
  value       = var.master3.ip
}

output "worker_ip" {
  description = "IP del Worker principal"
  value       = var.worker.ip
}

###############################################
# Mapa completo de IPs
###############################################

output "vm_ips" {
  description = "Todas las IPs del cluster OKD"
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master1   = var.master1.ip
    master2   = var.master2.ip
    master3   = var.master3.ip
    worker    = var.worker.ip
  }
}