# terraform\outputs.tf
# ================================
#  IPs Completas (Mapa)
# ================================
output "vm_ips" {
  description = "IPs de todas las máquinas virtuales"
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
}

# ================================
#  IPs Individuales
# ================================
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
