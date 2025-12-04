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
}
