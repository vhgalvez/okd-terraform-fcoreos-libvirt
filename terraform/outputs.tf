# terraform/outputs.tf

#############################################
# MAPA COMPLETO DE IPs
#############################################
output "vm_ips" {
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
}

output "infra_ip" {
  value = var.infra.ip
}

output "bootstrap_ip" {
  value = var.bootstrap.ip
}

output "master_ip" {
  value = var.master.ip
}

output "worker_ip" {
  value = var.worker.ip
}

#############################################
# RED
#############################################
output "network_name" {
  value = var.network_name
}

output "network_cidr" {
  value = var.network_cidr
}

#############################################
# POOL PATH (VERSIÓN ESTABLE 0.8.3)
#############################################
output "libvirt_pool_path" {
  value = libvirt_pool.okd.path
}
