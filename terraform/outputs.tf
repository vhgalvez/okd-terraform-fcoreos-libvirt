<<<<<<< HEAD
output "vm_ips" {
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
=======
# terraform/outputs.tf
output "infra_ip" {
  value       = var.infra.ip
  description = "IP del nodo infra (DNS+NTP)."
}

output "bootstrap_ip" {
  value       = var.bootstrap.ip
  description = "IP del nodo bootstrap."
}

output "master_ip" {
  value       = var.master.ip
  description = "IP del master."
}

output "worker_ip" {
  value       = var.worker.ip
  description = "IP del worker."
>>>>>>> 0d3d0830d724ed640ce167dc4bb0d1f511a4cd88
}
