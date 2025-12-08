# terraform/outputs.tf
output "libvirt_pool_path" {
  value = libvirt_pool.okd.target[0].path
}

output "network_name" {
  value = var.network_name
}

output "network_cidr" {
  value = var.network_cidr
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

output "vm_ips" {
  value = {
    infra     = var.infra.ip
    bootstrap = var.bootstrap.ip
    master    = var.master.ip
    worker    = var.worker.ip
  }
}
