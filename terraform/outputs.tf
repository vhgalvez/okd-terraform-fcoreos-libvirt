# terraform/outputs.tf
output "infra_ip" {
  value       = var.infra.address
  description = "IP del nodo infra (DNS+NTP)."
}

output "bootstrap_ip" {
  value       = var.bootstrap.address
  description = "IP del nodo bootstrap."
}

output "master_ip" {
  value       = var.master.address
  description = "IP del master."
}

output "worker_ip" {
  value       = var.worker.address
  description = "IP del worker."
}
